# app/controllers/fast_passes_controller.rb
class FastPassesController < ApplicationController
  before_action :exigir_estudante

  def index
    @sorteios = Sorteio.where("data >= ?", Date.current).order(:data, :id)
    @sorteio = if params[:sorteio_id].present?
      @sorteios.find(params[:sorteio_id])
    else
      @sorteios.where(status: "aberto").first || @sorteios.first
    end
    @restaurantes = Restaurante.where(id: @sorteio&.cotas&.keys || []).order(:nome)
    @restaurante = if params[:restaurante_id].present?
      @restaurantes.find(params[:restaurante_id])
    else
      @restaurantes.first
    end
    @cotas = @sorteio && @restaurante ? @sorteio.cotas_do_restaurante(@restaurante) : {}
    @janelas = TimeFrame.includes(:turno).where(id: @cotas.select { |_, quantidade| quantidade.positive? }.keys).order(:inicio, :id)
    @catracas = @restaurante ? @restaurante.catracas.where(modo_acesso: "fastpass").order(:id) : []
    @inscricoes = InscricaoFastpass.includes(:time_frame, :sorteio, catraca: :restaurante)
      .where(usuario_matricula: current_usuario.matricula, sorteio_id: @sorteio&.id).order(:id)
  end

  def create
    FastPasses::CriarInscricaoService.new(current_usuario, params[:time_frame_id],
      params[:restaurante_id], params[:catraca_id], sorteio_id: params[:sorteio_id]).call
    redirect_to student_fast_pass_path(sorteio_id: params[:sorteio_id], restaurante_id: params[:restaurante_id]),
      notice: "Inscrição realizada. Aguarde o resultado do sorteio."
  rescue ArgumentError, ActiveRecord::RecordInvalid => erro
    redirect_to student_fast_pass_path(sorteio_id: params[:sorteio_id], restaurante_id: params[:restaurante_id]), alert: erro.message
  end

  private

  def exigir_estudante
    return if current_usuario&.estudante?

    redirect_to login_path, alert: "Acesso restrito a estudantes."
  end
end
