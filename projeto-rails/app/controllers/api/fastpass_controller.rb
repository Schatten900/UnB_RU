module Api
  class FastpassController < ApplicationController
    before_action :authenticate_usuario!
    before_action :exigir_operador
    before_action :carregar_contexto

    def create
      unless @catraca.modo_acesso == "fastpass"
        return render json: { erro: "Selecione uma catraca FastPass.", motivo: "modo_nao_fastpass" }, status: :conflict
      end

      estudante = Usuario.find_by(matricula: params[:matricula].to_s)
      unless estudante&.estudante?
        return render json: { erro: "Estudante não encontrado.", motivo: "usuario_invalido" }, status: :not_found
      end

      agora = Time.current.in_time_zone("America/Sao_Paulo")
      inscricao = InscricaoFastpass.joins(:sorteio, :time_frame)
                                  .includes(:time_frame)
                                  .where(usuario_matricula: estudante.matricula,
                                         sorteios: { data: agora.to_date },
                                         time_frames: { turno_id: @turno.id })
                                  .order(:id).first
      resultado = ValidacaoFastpassService.call(
        usuario: estudante, catraca: @catraca, turno: @turno,
        inscricao: inscricao, time_frame: inscricao&.time_frame,
        liberador: LiberadorCatracaMock.new, agora: agora
      )
      render json: dados_acesso(resultado.acesso).merge(
        autorizado: resultado.autorizado?, motivo: resultado.motivo
      ), status: resultado.autorizado? ? :created : :unprocessable_content
    end

    def confirmar
      # A identificação da tentativa é suficiente; o cliente não pode informar
      # autorização, valor, estudante ou catraca para forjar uma confirmação.
      acesso = Acesso.where(catraca: @catraca, turno: @turno).find(params[:id])
      resultado = ValidacaoFastpassService::Resultado.new(
        autorizado: acesso.status == "pendente" && acesso.inscricao_fastpass_id.present?,
        acesso: acesso, confirmado: acesso.passagem_em.present?
      )
      confirmado = ConfirmacaoPassagemFastpassService.call(resultado: resultado)
      render json: dados_acesso(confirmado).merge(motivo: "passagem_confirmada")
    rescue ActiveRecord::RecordNotFound
      render json: { erro: "Tentativa não encontrada neste ponto de acesso." }, status: :not_found
    rescue ConfirmacaoPassagemFastpassService::PassagemJaConfirmada
      render json: { erro: "Passagem já confirmada.", motivo: "passagem_ja_confirmada" }, status: :conflict
    rescue ConfirmacaoPassagemFastpassService::PassagemNaoAutorizada
      render json: { erro: "Tentativa sem autorização FastPass.", motivo: "passagem_nao_autorizada" }, status: :conflict
    rescue ConfirmacaoPassagemFastpassService::SaldoInsuficiente
      render json: { erro: "Saldo insuficiente.", motivo: "saldo_insuficiente" }, status: :unprocessable_content
    end

    private

    def exigir_operador
      return if current_usuario.funcionario? || current_usuario.administrador?

      render json: { erro: "Acesso restrito a operadores." }, status: :forbidden
    end

    def carregar_contexto
      @catraca = restaurante_atual&.catracas&.find_by(id: session[:catraca_id])
      @turno = current_usuario.turno
      return if @catraca && @turno

      render json: { erro: "Configure o restaurante e a catraca e vincule um turno ao operador.",
                     motivo: "contexto_nao_configurado" }, status: :conflict
    end

    def dados_acesso(acesso)
      {
        acesso_id: acesso.id, status: acesso.status,
        matricula: acesso.usuario_matricula, catraca_id: acesso.catraca_id,
        turno_id: acesso.turno_id, passagem_em: acesso.passagem_em,
        valor_debitado: acesso.valor_debitado.to_s("F"),
        saldo: acesso.usuario.reload.saldo.to_s("F")
      }
    end
  end
end
