
module Relatorios
  class RelatorioOperacoesPdf
    def self.generate
      Prawn::Document.new do |pdf|
        pdf.text(
          "Relatório Global de Operações",
          size: 20,
          style: :bold
        )

        pdf.move_down 20

        pdf.text "RECARGAS", size: 16, style: :bold
        pdf.move_down 10

        Recarga.includes(:usuario).find_each do |recarga|
          pdf.text "Recarga ##{recarga.id}"
          pdf.text "Matrícula: #{recarga.usuario_matricula}"
          pdf.text "Valor: R$ #{recarga.valor}"
          pdf.text "Método: #{recarga.metodo}"
          pdf.text "Status: #{recarga.status}"
          pdf.text "Data: #{recarga.data_hora}"

          pdf.move_down 10
        end

        pdf.move_down 20

        pdf.text "ACESSOS", size: 16, style: :bold
        pdf.move_down 10

        Acesso.includes(:usuario).find_each do |acesso|
          pdf.text "Acesso ##{acesso.id}"
          pdf.text "Matrícula: #{acesso.usuario_matricula}"
          pdf.text "Turno: #{acesso.turno_id}"
          pdf.text "Status: #{acesso.status}"
          pdf.text "Valor debitado: R$ #{acesso.valor_debitado}"

          pdf.move_down 10
        end
      end.render
    end
  end
end
#AI: GPT desktop, no think
#Prompt and strategy: First, we warmed GPT up by asking for file structure given the proposed feature, then we asked for a code with our project's specs, this was consolidated with other .rb
