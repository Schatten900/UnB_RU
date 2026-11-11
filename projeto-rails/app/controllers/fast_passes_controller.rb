#controllers/fast_passes_controller.rb
class FastPassesController < ApplicationController
  before_action :authenticate_usuario!

  def index
    @usuario = current_usuario
    @sorteio_ativo = Sorteio.where(status: "aberto").order(id: :desc).first || Sorteio.create(data: Date.current, status: "aberto")
    
    # Garante de forma forçada que será um Array (nunca nil)
    @turnos = Turno.includes(:time_frames).order(:inicio).to_a || []
    
    turno_id_param = params[:turno_id] || @turnos.first&.id
    @turno_selecionado = @turnos.find { |t| t.id.to_s == turno_id_param.to_s } || @turnos.first

    @time_frames = @turno_selecionado ? @turno_selecionado.time_frames.order(:inicio) : []

    @inscricao_atual = InscricaoFastpass
            .includes(:time_frame, :sorteio, catraca: :restaurante)
        .where(
        usuario_matricula: @usuario.matricula,
        resultado: InscricaoFastpass::RESULTADO_GANHOU
    )
        .order(id: :desc)
        .first
    @restaurantes = Restaurante.includes(:catracas).order(:nome)


    @restaurante_selecionado =
        @inscricao_atual&.catraca&.restaurante ||
        @restaurantes.first


    @catracas = @restaurante_selecionado ?
        @restaurante_selecionado.catracas.where(modo_acesso: "fastpass") : []
    end
end

# AI: Gemini and chatgpt
# Prompt: Created with Gemini through natural language conversation about fast pass, general idea, models, existing controllers were passed, and then the AI was asked to modify it.