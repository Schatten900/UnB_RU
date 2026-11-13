module Api
  class FastPassesController < ApplicationController
    before_action :authenticate_usuario!

    def create
      unless current_usuario.estudante?
        return render json: { erro: "Inscrição permitida somente para estudantes." }, status: :forbidden
      end

      inscricao = ::FastPasses::CriarInscricaoService.new(current_usuario,
        params[:time_frame_id], params[:restaurante_id], params[:catraca_id],
        sorteio_id: params[:sorteio_id]).call
      render json: { mensagem: "Inscrição realizada. Aguarde o resultado do sorteio.",
        inscricao: inscricao, time_frame: inscricao.time_frame,
        restaurante: inscricao.catraca.restaurante, catraca: inscricao.catraca }, status: :created
    rescue ArgumentError, ActiveRecord::RecordInvalid => erro
      render json: { erro: erro.message }, status: :unprocessable_content
    end
  end
end
