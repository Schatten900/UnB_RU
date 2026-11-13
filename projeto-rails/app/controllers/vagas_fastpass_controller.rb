class VagasFastpassController < ApplicationController
  before_action :exigir_administrador

  def index
    @restaurantes = Restaurante.order(:nome)
    @restaurante = if params[:restaurante_id].present?
      @restaurantes.find(params[:restaurante_id])
    else
      @restaurantes.first
    end
    @data = Date.iso8601(params.fetch(:data, Date.current.to_s))
    @janelas = TimeFrame.includes(:turno).order(:inicio, :id)
    @sorteio = sorteio = Sorteio.find_by(data: @data)
    @cotas = sorteio && @restaurante ? sorteio.cotas_do_restaurante(@restaurante).transform_keys(&:to_i) : {}
    @cota_diaria = @cotas.values.sum
  rescue Date::Error
    redirect_to admin_vagas_fastpass_path, alert: "Informe uma data válida."
  end

  def aplicar
    restaurante = Restaurante.find(params[:restaurante_id])
    ConfiguracaoCotasFastpassService.call(restaurante: restaurante, data: params[:data],
      cota_diaria: params[:cota_diaria], cotas: params.fetch(:cotas, ActionController::Parameters.new).permit!.to_h)
    redirect_to admin_vagas_fastpass_path(restaurante_id: restaurante.id, data: params[:data]), notice: "Cotas salvas para o sorteio."
  rescue ArgumentError, ActiveRecord::RecordInvalid => erro
    redirect_to admin_vagas_fastpass_path(restaurante_id: params[:restaurante_id]), alert: erro.message
  end

  def sortear
    sorteio = Sorteio.find(params[:sorteio_id])
    FastPasses::RealizarSorteioService.call(sorteio: sorteio)
    NotificarFastPassJob.perform_later(sorteio.id)
    redirect_to admin_vagas_fastpass_path(data: sorteio.data, restaurante_id: params[:restaurante_id]),
      notice: "Sorteio concluído para todos os restaurantes configurados. Resultados disponíveis aos estudantes."
  rescue ArgumentError => erro
    redirect_to admin_vagas_fastpass_path(data: sorteio&.data, restaurante_id: params[:restaurante_id]), alert: erro.message
  end

  private

  def exigir_administrador
    return if usuario_atual&.administrador?

    redirect_to login_path, alert: "Acesso não autorizado."
  end
end
