#controllers/api/fast_passes_controllers.rb
module Api
  class FastPassesController < ApplicationController
    before_action :authenticate_usuario!

    def create
      inscricao = ::FastPasses::CriarInscricaoService.new(
        current_usuario,
        params[:time_frame_id],
        params[:restaurante_id],
        params[:catraca_id]
      ).call
      
      
      render json: {
        mensagem: "Inscrição no sorteio realizada com sucesso!",
        inscricao: inscricao,
        time_frame: inscricao.time_frame,
        restaurante: inscricao.catraca.restaurante,
        catraca: inscricao.catraca
      }, status: :created

    rescue ArgumentError, ActiveRecord::RecordInvalid => e
      render json: { erro: e.message }, status: :unprocessable_entity
    end
  end
end


# AI: Gemini and chatgpt
# Prompt: Modified with Gemini through natural language conversation about fast pass, general idea, models, existing controllers were passed, and then the AI was asked to modify it.