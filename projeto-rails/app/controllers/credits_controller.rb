
module Api
  class CreditsController < ApplicationController
    before_action :authenticate_user!

    def create
      transaction = Payments::CreatePayment.new(
        current_user.account,
        params[:amount],
        params[:payment_method]
      ).call

      render json: {
        message: "Crédito adicionado com sucesso",
        transaction: transaction,
        balance: current_user.account.balance,
        pending_balance: current_user.account.pending_balance
      }, status: :created

    rescue ArgumentError, ActiveRecord::RecordInvalid
      render json: {
        error: "Por favor, insira um valor de crédito válido"
      }, status: :unprocessable_entity
    end

    def confirm
      transaction = current_user.account.transactions.find(params[:id])

      current_user.account.with_lock do
        transaction.reload

        raise ArgumentError, "Pagamento já processado" unless
          transaction.pending?

        current_user.account.increment!(
          :balance,
          transaction.amount
        )

        current_user.account.decrement!(
          :pending_balance,
          transaction.amount
        )

        transaction.update!(status: :paid)
      end

      render json: {
        message: "Pagamento confirmado",
        balance: current_user.account.balance,
        pending_balance: current_user.account.pending_balance
      }
    rescue ArgumentError, ActiveRecord::RecordInvalid
      render json: {
        error: "Não foi possível confirmar o pagamento"
      }, status: :unprocessable_entity
    end
  end
end



#AI: GPT desktop, no think
#Prompt and strategy: First, we warmed GPT up by asking for file structure given the proposed feature, then we asked for a code with our project's specs, this was consolidated with other .rb