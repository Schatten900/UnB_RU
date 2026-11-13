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
    def liberar_passagem
      acesso = ::FastPasses::ConfirmarPassagemService.new(
        current_usuario,
        params[:catraca_id]
      ).call

      time_frame = acesso.inscricao_fastpass.time_frame

      render json: {
        sucesso: true,
        mensagem: "Catraca liberada! Passagem confirmada para o horário entre #{time_frame.inicio.strftime('%H:%M')} e #{time_frame.fim.strftime('%H:%M')}.",
        acesso: acesso
      }, status: :ok

    rescue ::FastPasses::ConfirmarPassagemService::PassagemNegada,
           ActiveRecord::RecordInvalid,
           ActiveRecord::RecordNotFound => e
      render json: { erro: e.message }, status: :unprocessable_entity
    end
  end
end
