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
    render json: { erro: "Autorização inválida ou de outra catraca." }, status: :not_found
  end

  def index; end

  def processar_leitura
    raise ArgumentError, "Informe a matrícula recebida na leitura." if params[:matricula].to_s.strip.blank?

    simular("ok")
  end

  def simular_ok
    simular("ok")
  end

  def simular_fora_janela
    simular("fora_janela")
  end

  def simular_sem_saldo
    simular("sem_saldo")
  end

  def simular_modo_comum
    simular("modo_comum")
  end

  def confirmar_passagem
    acesso = Acesso.find_signed!(params[:autorizacao], purpose: finalidade_autorizacao)
    raise ActiveRecord::RecordNotFound unless acesso.catraca_id == @catraca_operador.id

    if acesso.passagem_em || acesso.status != "pendente"
      return render json: { erro: "Esta passagem já foi confirmada ou está bloqueada." }, status: :conflict
    end

    resultado = ValidacaoFastpassService::Resultado.new(autorizado: true, acesso: acesso, confirmado: false)
    ConfirmacaoPassagemFastpassService.call(resultado: resultado)
    inscricao = InscricaoFastpass.find_by(id: acesso.inscricao_fastpass_id)
    responder(acesso, modo: inscricao ? "fastpass" : "normal", janela: inscricao&.time_frame, confirmado: true)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    render json: { erro: "Autorização inválida ou expirada. Faça uma nova leitura." }, status: :not_found
  rescue ConfirmacaoPassagemFastpassService::SaldoInsuficiente
    render json: { erro: "Não foi possível confirmar: saldo insuficiente ou passagem já confirmada." }, status: :conflict
  end

  private

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
  def exigir_ponto_configurado
    return if @catraca_operador

    render json: { erro: "Configure um restaurante e uma catraca antes de simular." }, status: :unprocessable_content
  end

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

  def finalidade_autorizacao
    "simulacao_terminal:#{usuario_atual.matricula}:#{@catraca_operador.id}"
  end

  def responder(acesso, modo:, janela: nil, autorizado: true, motivo: :autorizado, confirmado: false, origem_leitura: nil)
    carregar_contexto
    estudante = acesso.usuario.reload
    render json: {
      acesso_id: acesso.id, modo: modo, autorizado: autorizado, motivo: motivo,
      confirmado: confirmado, horario: acesso.data_hora.iso8601, origem_leitura: origem_leitura,
      estudante: { nome: estudante.nome, matricula: estudante.matricula, saldo: estudante.saldo.to_f },
      tarifa: acesso.turno.preco.to_f, valor_debitado: acesso.valor_debitado.to_f,
      janela: janela && "#{janela.inicio.strftime('%H:%M')} – #{janela.fim.strftime('%H:%M')}",
      autorizacao: autorizado && !confirmado ? acesso.signed_id(purpose: finalidade_autorizacao, expires_in: 15.minutes) : nil,
      registros_html: render_to_string(partial: "terminal_validacao/acessos", formats: [:html], locals: { titulo: "Últimas validações registradas" })
    }
  end
end
