module Api
  class FastpassController < ApplicationController
    before_action :authenticate_usuario!
    before_action :exigir_operador
    before_action :carregar_contexto

    # Valida a matrícula lida no ponto FastPass configurado.
    # Lê a requisição e a sessão; retorna JSON 201 ou 4xx e registra a tentativa, sem débito.
    def create
      unless @catraca.modo_acesso == 'fastpass'
        return render json: { erro: 'Selecione uma catraca FastPass.', motivo: 'modo_nao_fastpass' }, status: :conflict
      end

      estudante = Usuario.find_by(matricula: params[:matricula].to_s)
      unless estudante&.estudante?
        return render json: { erro: 'Estudante não encontrado.', motivo: 'usuario_invalido' }, status: :not_found
      end

      resultado = validar_estudante(estudante)
      render json: dados_acesso(resultado.acesso).merge(
        autorizado: resultado.autorizado?, motivo: resultado.motivo
      ), status: resultado.autorizado? ? :created : :unprocessable_content
    end

    # Confirma a passagem autorizada pelo identificador recebido.
    # Retorna JSON 200 ou 4xx; atualiza o acesso e debita o saldo em transação.
    def confirmar
      # A identificação da tentativa é suficiente; o cliente não pode informar
      # autorização, valor, estudante ou catraca para forjar uma confirmação.
      acesso = Acesso.where(catraca: @catraca, turno: @turno).find(params[:id])
      resultado = resultado_pendente(acesso)
      confirmado = ConfirmacaoPassagemFastpassService.call(resultado: resultado)
      render json: dados_acesso(confirmado).merge(motivo: 'passagem_confirmada')
    rescue ActiveRecord::RecordNotFound
      render json: { erro: 'Tentativa não encontrada neste ponto de acesso.' }, status: :not_found
    rescue ConfirmacaoPassagemFastpassService::PassagemJaConfirmada
      render json: { erro: 'Passagem já confirmada.', motivo: 'passagem_ja_confirmada' }, status: :conflict
    rescue ConfirmacaoPassagemFastpassService::PassagemNaoAutorizada
      render json: { erro: 'Tentativa sem autorização FastPass.', motivo: 'passagem_nao_autorizada' }, status: :conflict
    rescue ConfirmacaoPassagemFastpassService::SaldoInsuficiente
      render json: { erro: 'Saldo insuficiente.', motivo: 'saldo_insuficiente' }, status: :unprocessable_content
    end

    private

    # Valida o estudante recebido usando sua inscrição do dia e o contexto do operador.
    # Retorna Resultado; consulta o banco e registra a tentativa sem debitar o saldo.
    def validar_estudante(estudante)
      agora = Time.current.in_time_zone('America/Sao_Paulo')
      inscricao = inscricao_do_dia(estudante, agora)
      ValidacaoFastpassService.call(
        usuario: estudante, catraca: @catraca, turno: @turno,
        inscricao: inscricao, time_frame: inscricao&.time_frame,
        liberador: LiberadorCatracaMock.new, agora: agora
      )
    end

    # Busca a inscrição do estudante recebido na data de agora e no turno configurado.
    # Retorna InscricaoFastpass ou nil; consulta o banco sem alterar registros.
    def inscricao_do_dia(estudante, agora)
      InscricaoFastpass.joins(:sorteio, :time_frame).includes(:time_frame)
                       .where(usuario_matricula: estudante.matricula,
                              sorteios: { data: agora.to_date },
                              time_frames: { turno_id: @turno.id })
                       .order(:id).first
    end

    # Reconstrói a autorização a partir do acesso recebido.
    # Retorna Resultado com o estado persistido, sem alterar o banco.
    def resultado_pendente(acesso)
      ValidacaoFastpassService::Resultado.new(
        autorizado: acesso.status == 'pendente' && acesso.inscricao_fastpass_id.present?,
        acesso: acesso, confirmado: acesso.passagem_em.present?
      )
    end

    # Exige funcionário ou administrador na sessão autenticada.
    # Sem argumentos; retorna nil ou JSON 403, sem gravar no banco.
    def exigir_operador
      return if current_usuario.funcionario? || current_usuario.administrador?

      render json: { erro: 'Acesso restrito a operadores.' }, status: :forbidden
    end

    # Carrega catraca e turno do operador a partir da sessão e do cadastro.
    # Sem argumentos; retorna nil ou JSON 409 e consulta o banco.
    def carregar_contexto
      @catraca = restaurante_atual&.catracas&.find_by(id: session[:catraca_id])
      @turno = current_usuario.turno
      return if @catraca && @turno

      render json: { erro: 'Configure o restaurante e a catraca e vincule um turno ao operador.',
                     motivo: 'contexto_nao_configurado' }, status: :conflict
    end

    # Serializa o acesso recebido e o saldo atualizado do estudante.
    # Retorna Hash; recarrega o usuário no banco sem alterar registros.
    def dados_acesso(acesso)
      {
        acesso_id: acesso.id, status: acesso.status,
        matricula: acesso.usuario_matricula, catraca_id: acesso.catraca_id,
        turno_id: acesso.turno_id, passagem_em: acesso.passagem_em,
        valor_debitado: acesso.valor_debitado.to_s('F'),
        saldo: acesso.usuario.reload.saldo.to_s('F')
      }
    end
  end
end
