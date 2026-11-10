require "csv"
require "prawn"

module Relatorios
  class HistoricoLocalExportacao
    CABECALHOS = ["Data/hora", "Matrícula", "Vínculo FastPass", "Turno", "Status", "Passagem", "Valor debitado (R$)"].freeze

    def self.csv(acessos:)
      # BOM para que programas de planilhas reconhecam UTF-8 corretamente.
      "\uFEFF" + CSV.generate(col_sep: ";") do |arquivo|
        arquivo << CABECALHOS
        acessos.each do |acesso|
          arquivo << [
            data_hora(acesso.data_hora),
            acesso.usuario_matricula,
            vinculo(acesso),
            acesso.turno.nome,
            acesso.status,
            data_hora(acesso.passagem_em),
            format("%.2f", acesso.valor_debitado).tr(".", ",")
          ]
        end
      end
    end

    def self.pdf(acessos:, catraca:)
      Prawn::Document.new(page_size: "A4", margin: 38) do |pdf|
        pdf.fill_color "06449A"
        pdf.text "RU UnB  |  Histórico local", size: 18, style: :bold
        pdf.move_down 8
        pdf.fill_color "20252B"
        pdf.text "Unidade: #{catraca.restaurante.nome}", size: 10
        pdf.text "Catraca #{catraca.id} - Piso #{catraca.piso}", size: 10
        pdf.text "Registros exportados: #{acessos.size}", size: 10
        pdf.move_down 14
        pdf.stroke_horizontal_rule
        pdf.move_down 12

        if acessos.empty?
          pdf.text "Nenhuma tentativa encontrada para os filtros informados.", size: 10
        else
          acessos.each do |acesso|
            pdf.start_new_page if pdf.cursor < 70
            pdf.text "#{data_hora(acesso.data_hora)}  |  #{acesso.usuario_matricula}  |  #{acesso.status.capitalize}",
                     size: 10, style: :bold
            pdf.move_down 3
            pdf.text "#{vinculo(acesso)}  |  #{acesso.turno.nome}  |  Débito: R$ #{format('%.2f', acesso.valor_debitado).tr('.', ',')}  |  Passagem: #{data_hora(acesso.passagem_em)}",
                     size: 8
            pdf.move_down 7
            pdf.stroke_color "E7E8EB"
            pdf.stroke_horizontal_rule
            pdf.move_down 10
          end
        end
      end.render
    end

    def self.data_hora(valor)
      valor ? valor.in_time_zone("America/Sao_Paulo").strftime("%d/%m/%Y %H:%M:%S") : "-"
    end

    def self.vinculo(acesso)
      acesso.inscricao_fastpass_id.present? ? "FastPass vinculado" : "Sem vínculo registrado"
    end
  end
end
