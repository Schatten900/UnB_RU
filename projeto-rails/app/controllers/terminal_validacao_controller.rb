# Controla a tela do terminal de validação.
#
# Exige um operador (funcionário em controle da catraca) e usa a catraca configurada na sessão.
class TerminalValidacaoController < ApplicationController
  before_action :exigir_funcionario
  before_action :carregar_contexto
  before_action :exigir_ponto_configurado, except: :index

  # Tratamento de erros
  # Parâmetros inválidos
  rescue_from ArgumentError, ActiveRecord::RecordInvalid do |erro|
    render json: { erro: erro.message }, status: :unprocessable_content
  end

  # Registro não encontrado
  rescue_from ActiveRecord::RecordNotFound do
    render json: { erro: 'Autorização inválida ou de outra catraca.' }, status: :not_found
  end

  # Exibe a tela do terminal.
  def index; end

  # Confirma a passagem do usuário informado em +usuario_matricula+
  #
  # Envia JSON com os dados da confirmação ou o motivo da falha
  # Trata passagem negada e tentativa de reutilização do FastPass
  def liberar_passagem
    return unless validar_dados_liberacao

    estudante = localizar_estudante
    return unless estudante

    acesso = confirmar_acesso(estudante)

    render json: dados_passagem_confirmada(acesso, estudante), status: :ok
  rescue FastPasses::ConfirmarPassagemService::PassagemNegada => e
    render json: { sucesso: false, erro: e.message },
           status: :unprocessable_content
  rescue ActiveRecord::RecordNotUnique
    render json: {
      sucesso: false,
      erro: 'Este FastPass já foi utilizado.'
    }, status: :unprocessable_content
  end

  # Verifica a configuração da catraca e a presença de +usuario_matricula+.
  #
  # Retorna true se os dados estiverem presentes, caso contrário retorna um status
  # HTTP 422 (unprocessable_entity)
  def validar_dados_liberacao
    unless @catraca_operador
      render json: {
        erro: 'Nenhuma catraca está configurada para este terminal.'
      }, status: :unprocessable_content
      return false
    end

    if params[:usuario_matricula].blank?
      render json: {
        erro: 'Matrícula do estudante não informada.'
      }, status: :unprocessable_content
      return false
    end

    true
  end

  # Busca o Usuario pela matrícula recebida em +usuario_matricula+.
  #
  # Retorna o usuário ou nil. No caso nil é renderizado que o Estudante não foi encontrado
  def localizar_estudante
    estudante = Usuario.find_by(matricula: params[:usuario_matricula])
    return estudante if estudante

    render json: { erro: 'Estudante não encontrado.' }, status: :not_found
    nil
  end

  # Passa a confirmação ao FastPasses::ConfirmarPassagemService.
  #
  # +estudante+ é o Usuario que solicitou a passagem na catraca do terminal.
  # Retorna o Acesso confirmado.
  def confirmar_acesso(estudante)
    FastPasses::ConfirmarPassagemService.new(
      estudante,
      @catraca_operador.id
    ).call
  end

  # Retorna os dados de uma passagem confirmada.
  #
  # +acesso+ é o Acesso confirmado; +estudante+ é o Usuario associado.
  # O retorno contém a mensagem, horário, valor debitado e o saldo final.
  def dados_passagem_confirmada(acesso, estudante)
    {
      sucesso: true,
      mensagem: mensagem_passagem_confirmada(acesso),
      horario: acesso.passagem_em.strftime('%H:%M'),
      valor_debitado: acesso.valor_debitado,
      saldo_atual: estudante.reload.saldo
    }
  end

  # Retorna a mensagem de confirmação com os horários da janela FastPass.
  #
  # +acesso+ deve possuir a inscrição no FastPass.
  def mensagem_passagem_confirmada(acesso)
    janela = acesso.inscricao_fastpass.time_frame
    inicio = janela.inicio.strftime('%H:%M')
    fim = janela.fim.strftime('%H:%M')

    "Catraca liberada! Passagem confirmada entre #{inicio} e #{fim}."
  end

  # Processa a matrícula informada.
  #
  # Registra a leitura e retorna a validação sem debitar antes da confirmação.
  # Matrículas vazias ou desconhecidas geram erro, sem seleção automática.
  def processar_leitura
    resultado = ProcessamentoLeituraTerminalService.call(
      catraca: @catraca_operador, turno: @turno_operador,
      modo: params[:modo], matricula: params[:matricula]
    )
    responder(
      resultado.validacao.acesso, modo: resultado.modo, janela: resultado.janela,
                                  autorizado: resultado.validacao.autorizado?, motivo: resultado.validacao.motivo,
                                  origem_leitura: 'informada'
    )
  end

  # Executa a simulação do cenário ok
  def simular_ok
    simular('ok')
  end

  # Executa a simulação de leitura fora da janela de horário.
  def simular_fora_janela
    simular('fora_janela')
  end

  # Executa a simulação de leitura com saldo insuficiente.
  def simular_sem_saldo
    simular('sem_saldo')
  end

  # Executa a simulação de leitura no modo de acesso comum.
  def simular_modo_comum
    simular('modo_comum')
  end

  # Confirma uma passagem pendente usando o token recebido em +autorizacao+
  #
  # Verifica a finalidade do token e a catraca antes de chamar o serviço
  # Envia o JSON com a confirmação ou erro de token, saldo ou estado da passagem
  def confirmar_passagem
    acesso = Acesso.find_signed!(params[:autorizacao], purpose: finalidade_autorizacao)
    raise ActiveRecord::RecordNotFound unless acesso.catraca_id == @catraca_operador.id

    if acesso.passagem_em || acesso.status != 'pendente'
      return render json: { erro: 'Esta passagem já foi confirmada ou está bloqueada.' }, status: :conflict
    end

    resultado = ValidacaoFastpassService::Resultado.new(autorizado: true, acesso: acesso, confirmado: false)
    ConfirmacaoPassagemFastpassService.call(resultado: resultado)
    inscricao = InscricaoFastpass.find_by(id: acesso.inscricao_fastpass_id)
    responder(acesso, modo: inscricao ? 'fastpass' : 'normal', janela: inscricao&.time_frame, confirmado: true)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    render json: { erro: 'Autorização inválida ou expirada. Faça uma nova leitura.' }, status: :not_found
  rescue ConfirmacaoPassagemFastpassService::SaldoInsuficiente
    render json: { erro: 'Não foi possível confirmar: saldo insuficiente ou passagem já confirmada.' },
           status: :conflict
  end

  private

  # Carrega restaurante, catraca e turno do operador para uso pela tela.
  #
  # Seleciona os 20 acessos mais recentes da catraca
  def carregar_contexto
    @restaurante_operador = restaurante_atual
    @catraca_operador = @restaurante_operador&.catracas&.find_by(id: session[:catraca_id])
    @turno_operador = usuario_atual.turno
    @acessos_operador = if @catraca_operador
                          Acesso.where(catraca_id: @catraca_operador.id)
                                .includes(:usuario)
                                .order(data_hora: :desc, id: :desc).limit(20)
                        else
                          Acesso.none
                        end
  end

  # Envia JSON com HTTP 422 se não houver catraca configurada.
  def exigir_ponto_configurado
    return if @catraca_operador

    render json: { erro: 'Configure um restaurante e uma catraca antes de simular.' }, status: :unprocessable_content
  end

  # Delega a leitura ao SimulacaoTerminalService e envia o resultado por #responder.
  #
  # +cenario+ identifica o cenário solicitado. Modo e matrícula vêm dos
  # parâmetros; catraca e turno vêm do contexto do operador.
  def simular(cenario)
    resultado = SimulacaoTerminalService.call(
      catraca: @catraca_operador, turno: @turno_operador,
      modo: params[:modo], cenario: cenario, matricula: params[:matricula]
    )
    responder(
      resultado.validacao.acesso, modo: resultado.modo, janela: resultado.janela,
                                  autorizado: resultado.validacao.autorizado?, motivo: resultado.validacao.motivo,
                                  origem_leitura: resultado.origem_leitura
    )
  end

  # Retorna a finalidade usada para assinar e verificar tokens de passagem
  #
  # Vincula o token a matrícula do operador e a catraca configurada
  def finalidade_autorizacao
    "simulacao_terminal:#{usuario_atual.matricula}:#{@catraca_operador.id}"
  end

  # Envia JSON com o resultado da validação e os dados para atualizar o terminal.
  #
  # Argumentos:
  # - +acesso+: registro de Acesso da leitura ou confirmação.
  # - +modo+: modalidade de acesso retornada ao terminal.
  # - +janela+: TimeFrame do FastPass, ou nil.
  # - +autorizado+: indica se a validação autorizou a passagem.
  # - +motivo+: motivo da autorização ou do bloqueio.
  # - +confirmado+: indica se a passagem já foi confirmada.
  # - +origem_leitura+: origem da leitura, quando informada.
  #
  # Atualiza o contexto e inclui dados do estudante, valores, janela, token e
  # HTML das últimas validações.
  def responder(acesso, modo:, janela: nil, autorizado: true, motivo: :autorizado, confirmado: false,
                origem_leitura: nil)
    carregar_contexto
    acesso.usuario.reload
    render json: {
      acesso_id: acesso.id, modo: modo, autorizado: autorizado, motivo: motivo,
      confirmado: confirmado, horario: acesso.data_hora.iso8601, origem_leitura: origem_leitura,
      estudante: dados_estudante(acesso),
      tarifa: acesso.turno.preco.to_f, valor_debitado: acesso.valor_debitado.to_f,
      janela: descricao_janela(janela),
      autorizacao: token_autorizacao(acesso, autorizado, confirmado),
      registros_html: registros_acessos_html
    }
  end

  # Retorna nome, matrícula e saldo do usuário de +acesso+.
  #
  # Recarrega o Usuario no banco para obter o saldo atualizado, convertido em Float.
  def dados_estudante(acesso)
    estudante = acesso.usuario.reload
    {
      nome: estudante.nome,
      matricula: estudante.matricula,
      saldo: estudante.saldo.to_f
    }
  end

  # Formata os horários de +janela+ como "HH:MM – HH:MM".
  #
  # Retorna nil quando não há janela.
  def descricao_janela(janela)
    return unless janela

    "#{janela.inicio.strftime('%H:%M')} – #{janela.fim.strftime('%H:%M')}"
  end

  # Gera um token para confirmar a passagem de +acesso+ em até 15 minutos.
  #
  # +autorizado+ e +confirmado+ indicam o estado da passagem.
  # Retorna nil se o acesso não estiver autorizado ou já estiver confirmado;
  # caso contrário, retorna o token vinculado ao operador e à catraca.
  def token_autorizacao(acesso, autorizado, confirmado)
    return unless autorizado
    return if confirmado

    acesso.signed_id(
      purpose: finalidade_autorizacao,
      expires_in: 15.minutes
    )
  end

  # Retorna o HTML da partial de últimas validações do terminal.
  #
  # Usa os acessos do contexto e o título "Últimas validações registradas".
  def registros_acessos_html
    render_to_string(
      partial: 'terminal_validacao/acessos',
      formats: [:html],
      locals: { titulo: 'Últimas validações registradas' }
    )
  end
end
