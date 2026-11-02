
module Payments
  class CreatePayment
    def initialize(account, amount, method)
      @account = account
      @amount = BigDecimal(amount.to_s)
      @method = method
    end

    def call
      raise ArgumentError, "Valor inválido" unless
        @amount.positive?

      raise ArgumentError, "Método inválido" unless
        %w[pix credit_card].include?(@method)

      account = @account

      account.with_lock do
        transaction = account.transactions.create!(
          amount: @amount,
          payment_method: @method,
          status: :pending
        )

        if @method == "pix"
          transaction.update!(
            pix_code: "PIX-MOCK-#{transaction.id}-#{SecureRandom.hex(4)}"
          )

          account.increment!(
            :pending_balance,
            @amount
          )
        else
          transaction.update!(status: :paid)

          account.increment!(
            :balance,
            @amount
          )
        end

        transaction
      end
    end
  end
end



#AI: GPT desktop, no think
#Prompt and strategy: First, we warmed GPT up by asking for file structure given the proposed feature, then we asked for a code with our project's specs, this was consolidated with other .rb