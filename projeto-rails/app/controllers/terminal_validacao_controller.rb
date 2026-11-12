
class TerminalValidacaoController < ApplicationController
  before_action :exigir_funcionario
  before_action :carregar_contexto

  def index; end

  def liberar_passagem
    unless @catraca_operador
      return render json: {
        erro: "Nenhuma catraca está configurada para este terminal."
      }, status: :unprocessable_entity
    end

    matricula = params[:usuario_matricula]

    if matricula.blank?
      return render json: {
        erro: "Matrícula do estudante não informada."
      }, status: :unprocessable_entity
    end

    estudante = Usuario.find_by(matricula: matricula)

    unless estudante
      return render json: {
        erro: "Estudante não encontrado."
      }, status: :not_found
    end

    acesso = FastPasses::ConfirmarPassagemService.new(
      estudante,
      @catraca_operador.id
    ).call

    render json: {
      sucesso: true,
      mensagem: mensagem: "Catraca liberada! Passagem confirmada entre #{acesso.inscricao_fastpass.time_frame.inicio.strftime('%H:%M')} e #{acesso.inscricao_fastpass.time_frame.fim.strftime('%H:%M')}.",
      horario: acesso.passagem_em.strftime("%H:%M"),
      valor_debitado: acesso.valor_debitado,
      saldo_atual: estudante.reload.saldo
    }, status: :ok

  rescue FastPasses::ConfirmarPassagemService::PassagemNegada => e
    render json: {
      sucesso: false,
      erro: e.message
    }, status: :unprocessable_entity

  rescue ActiveRecord::RecordNotUnique
    render json: {
      sucesso: false,
      erro: "Este FastPass já foi utilizado."
    }, status: :unprocessable_entity
  end

  private

  def carregar_contexto
    @restaurante_operador = restaurante_atual

    @catraca_operador =
      @restaurante_operador&.catracas&.find_by(id: session[:catraca_id])

    @turno_operador = usuario_atual.turno

    @acessos_operador = if @catraca_operador
      Acesso.where(catraca_id: @catraca_operador.id)
        .includes(:usuario)
        .order(data_hora: :desc)
        .limit(20)
    else
      Acesso.none
    end
  end
end

# AI: ChatGPT web
# Prompt and strategy: Asked on natural language, providing relevant files, on how to modify terminal_validacao_controller to integrate with accesses
