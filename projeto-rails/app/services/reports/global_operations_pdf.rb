
module Reports
  class GlobalOperationsPdf
    def self.generate
      Prawn::Document.new do |pdf|
        pdf.text(
          "Relatório Global de Operações",
          size: 20,
          style: :bold
        )

        pdf.move_down 20

        Transaction.includes(:account).find_each do |transaction|
          pdf.text "Transação ##{transaction.id}"
          pdf.text "Valor: R$ #{transaction.amount}"
          pdf.text "Método: #{transaction.payment_method}"
          pdf.text "Status: #{transaction.status}"

          pdf.move_down 10
        end
      end.render
    end
  end
end



#AI: GPT desktop, no think
#Prompt and strategy: First, we warmed GPT up by asking for file structure given the proposed feature, then we asked for a code with our project's specs, this was consolidated with other .rb