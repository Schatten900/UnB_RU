require "prawn"

class GeradorPdfHistorico
  Resultado = Struct.new(:simulado, :nome_arquivo, :tipo_mime, :conteudo, :lancamentos, keyword_init: true)

  def self.call(usuario:, lancamentos:, titulo: "Extrato e Histórico de Refeições")
    documento = Prawn::Document.new(page_size: "A4", margin: 38)
    documento.fill_color "06449A"
    documento.text texto("RU UnB | #{titulo}"), size: 17, style: :bold
    documento.move_down 12
    documento.fill_color "20252B"
    documento.text texto("Estudante: #{usuario.nome}"), size: 11
    documento.text texto("Matrícula: #{usuario.matricula}"), size: 10
    documento.text texto("Emitido em: #{Time.current.in_time_zone('America/Sao_Paulo').strftime('%d/%m/%Y %H:%M')} (Brasília)"), size: 9
    documento.text texto("Lançamentos exportados: #{lancamentos.size}"), size: 10
    documento.move_down 14

    if lancamentos.empty?
      documento.text texto("Nenhum lançamento encontrado para os filtros selecionados."), size: 11
    else
      lancamentos.each do |item|
        documento.start_new_page if documento.cursor < 110
        credito = item[:tipo] == "recarga"
        data = item[:data_hora].in_time_zone("America/Sao_Paulo").strftime("%d/%m/%Y %H:%M")
        nome = item[:nome] || (credito ? "Recarga de Saldo" : "Refeição")
        documento.text texto("#{data} | #{nome} | #{credito ? '+' : '-'} R$ #{moeda(item[:valor])}"), size: 10, style: :bold
        documento.text texto(item[:local]), size: 9 if item[:local]
        documento.text texto(item[:detalhe]), size: 9 if item[:detalhe]
        documento.text texto("Método: #{item[:metodo_nome]}"), size: 9 if item[:metodo_nome]
        documento.move_down 8
        documento.stroke_color "E7E8EB"
        documento.stroke_horizontal_rule
        documento.move_down 10
      end
    end

    documento.start_new_page if documento.cursor < 80
    creditos = lancamentos.select { |item| item[:tipo] == "recarga" }.sum { |item| item[:valor] }
    debitos = lancamentos.reject { |item| item[:tipo] == "recarga" }.sum { |item| item[:valor] }
    documento.text texto("Total de recargas: R$ #{moeda(creditos)}"), size: 10
    documento.text texto("Total de refeições: R$ #{moeda(debitos)}"), size: 10
    documento.number_pages "Página <page> de <total>", at: [documento.bounds.right - 120, -15], align: :right, size: 8

    Resultado.new(
      simulado: false, nome_arquivo: "extrato_#{usuario.matricula}.pdf",
      tipo_mime: "application/pdf", conteudo: documento.render, lancamentos: lancamentos
    )
  end

  def self.moeda(valor)
    format("%.2f", valor).tr(".", ",")
  end

  def self.texto(valor)
    valor.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").encode("UTF-8")
  end
  private_class_method :moeda, :texto
end
