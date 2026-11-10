class TerminalValidacaoController < ApplicationController
  before_action :exigir_funcionario
  before_action :carregar_contexto

  def index; end

  private

  def carregar_contexto
    @restaurante_operador = restaurante_atual
    @catraca_operador = @restaurante_operador&.catracas&.find_by(id: session[:catraca_id])
    @turno_operador = usuario_atual.turno
    @acessos_operador = if @catraca_operador
      Acesso.where(catraca_id: @catraca_operador.id)
            .includes(:usuario)
            .order(data_hora: :desc).limit(20)
    else
      Acesso.none
    end
  end
end
