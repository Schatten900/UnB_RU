require 'csv'
require 'prawn'

module Relatorios
  class HistoricoLocalExportacao
    CABECALHOS = ['Data/hora', 'Matrícula', 'Vínculo FastPass', 'Turno', 'Status', 'Passagem',
                  'Valor debitado (R$)'].freeze

    # Gera o CSV da coleção de acessos recebida com cabeçalho e BOM.
    # Retorna String; pode carregar associações, sem gravar no banco.
    def self.csv(acessos:)
      # BOM para que programas de planilhas reconhecam UTF-8 corretamente.
      "\uFEFF" + CSV.generate(col_sep: ';') do |arquivo|
        arquivo << CABECALHOS
        acessos.each do |acesso|
          arquivo << linha_csv(acesso)
        end
      end
    end

    # Gera o PDF da coleção de acessos e da catraca recebidas.
    # Retorna String binária; pode carregar associações, sem gravar no banco.
    def self.pdf(acessos:, catraca:)
      documento = Prawn::Document.new(page_size: 'A4', margin: 38)
      cabecalho_pdf(documento, catraca, acessos.size)
      if acessos.empty?
        documento.text 'Nenhuma tentativa encontrada para os filtros informados.', size: 10
      else
        acessos.each { |acesso| registro_pdf(documento, acesso) }
      end
      documento.render
    end

    # Formata o horário recebido no fuso de Brasília.
    # Retorna String ou hífen para nil; não altera o valor.
    def self.data_hora(valor)
      valor ? valor.in_time_zone('America/Sao_Paulo').strftime('%d/%m/%Y %H:%M:%S') : '-'
    end

    # Descreve o vínculo FastPass do acesso recebido.
    # Retorna String; não altera registros.
    def self.vinculo(acesso)
      acesso.inscricao_fastpass_id.present? ? 'FastPass vinculado' : 'Sem vínculo registrado'
    end

    # Converte o acesso recebido em uma linha CSV.
    # Retorna Array; pode carregar o turno, sem alterar registros.
    def self.linha_csv(acesso)
      [data_hora(acesso.data_hora), acesso.usuario_matricula, vinculo(acesso),
       acesso.turno.nome, acesso.status, data_hora(acesso.passagem_em), moeda(acesso.valor_debitado)]
    end

    # Desenha no pdf recebido o cabeçalho da catraca e a quantidade informadas.
    # Retorna a posição final; altera o documento em memória e pode consultar associações.
    def self.cabecalho_pdf(pdf, catraca, quantidade)
      pdf.fill_color '06449A'
      pdf.text 'RU UnB  |  Histórico local', size: 18, style: :bold
      pdf.move_down 8
      pdf.fill_color '20252B'
      pdf.text "Unidade: #{catraca.restaurante.nome}", size: 10
      pdf.text "Catraca #{catraca.id} - Piso #{catraca.piso}", size: 10
      pdf.text "Registros exportados: #{quantidade}", size: 10
      pdf.move_down 14
      pdf.stroke_horizontal_rule
      pdf.move_down 12
    end

    # Desenha o acesso no pdf recebido, abrindo página quando necessário.
    # Retorna a posição final; altera o documento em memória e pode consultar associações.
    def self.registro_pdf(pdf, acesso)
      pdf.start_new_page if pdf.cursor < 70
      pdf.text "#{data_hora(acesso.data_hora)}  |  #{acesso.usuario_matricula}  |  #{acesso.status.capitalize}",
               size: 10, style: :bold
      pdf.move_down 3
      pdf.text detalhe_acesso(acesso), size: 8
      pdf.move_down 7
      pdf.stroke_color 'E7E8EB'
      pdf.stroke_horizontal_rule
      pdf.move_down 10
    end

    # Formata turno, vínculo, débito e passagem do acesso recebido.
    # Retorna String; pode carregar associações sem gravar no banco.
    def self.detalhe_acesso(acesso)
      "#{vinculo(acesso)}  |  #{acesso.turno.nome}  |  Débito: R$ #{moeda(acesso.valor_debitado)}  |  Passagem: #{data_hora(acesso.passagem_em)}"
    end

    # Formata o valor recebido com duas casas decimais e vírgula.
    # Retorna String; não modifica o valor.
    def self.moeda(valor)
      format('%.2f', valor).tr('.', ',')
    end
    private_class_method :linha_csv, :cabecalho_pdf, :registro_pdf, :detalhe_acesso, :moeda
  end
end
