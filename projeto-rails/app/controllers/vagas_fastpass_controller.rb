class VagasFastpassController < ApplicationController
  before_action :exigir_administrador

  def index
    @restaurantes = Restaurante.order(:nome)
    @restaurante = if params[:restaurante_id].present?
      @restaurantes.find(params[:restaurante_id])
    else
      @restaurantes.first
    end
  end

  private

  def exigir_administrador
    return if usuario_atual&.administrador?

    redirect_to login_path, alert: "Acesso não autorizado."
  end
end
