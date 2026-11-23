#recargas_controller.rb
module Api
  class RecargasController < ApplicationController
    before_action :authenticate_usuario!

    def create
      recarga = Recargas::CriarRecarga.new(
        current_usuario,
        params[:valor],
        params[:metodo]
      ).call

      render json: {
        mensagem: "Recarga criada com sucesso",
        recarga: recarga,
        saldo: current_usuario.saldo,
        saldo_pendente: current_usuario.saldo_pendente
      }, status: :created

    rescue ArgumentError, ActiveRecord::RecordInvalid
      render json: {
        erro: "Por favor, insira um valor de crédito válido"
      }, status: :unprocessable_entity
    end

    def confirmar
      usuario = current_usuario
      recarga = usuario.recargas.find(params[:id])

      usuario.with_lock do
        recarga.reload

        unless recarga.pendente?
          raise ArgumentError
        end

        usuario.increment!(:saldo, recarga.valor)
        recarga.update!(status: :concluida)
      end

      render json: {
        mensagem: "Pagamento confirmado",
        saldo: usuario.saldo,
        saldo_pendente: usuario.saldo_pendente
      }

    rescue ArgumentError, ActiveRecord::RecordInvalid
      render json: {
        erro: "Não foi possível confirmar o pagamento"
      }, status: :unprocessable_entity
    end
  end
end
#AI: GPT desktop, no think
#Prompt and strategy: First, we warmed GPT up by asking for file structure given the proposed feature, then we asked for a code with our project's specs, this was consolidated with other .rb
