require "prawn"

class GeradorHistoricoPdf
  Resultado = Struct.new(:conteudo, :nome_arquivo, :tipo_mime, :lancamentos, keyword_init: true)

  def self.call(usuario:, lancamentos:)
    documento = Prawn::Document.new(page_size: "A4", margin: 38)
    documento.text "UnB - Restaurante Universitário", size: 18, style: :bold
    documento.move_down 8
    documento.text "Extrato e histórico de refeições", size: 14
    documento.text "Estudante: #{texto(usuario.nome)}"
    documento.text "Matrícula: #{usuario.matricula}"
    documento.text "Total de lançamentos: #{lancamentos.size}"
    documento.text "Horários de Brasília. Valores em reais.", size: 9
    documento.move_down 12
    documento.text "Nenhum lançamento encontrado para os filtros selecionados." if lancamentos.empty?

    lancamentos.each do |item|
      documento.start_new_page if documento.cursor < 80
      horario = item[:data_hora].in_time_zone(HistoricoEstudanteService::ZONA).strftime("%d/%m/%Y %H:%M")
      valor = format("%.2f", item[:valor]).tr(".", ",")
      sinal = item[:tipo] == "recarga" ? "+" : "-"
      documento.text "#{horario} | #{texto(item[:nome])} | #{sinal} R$ #{valor}", size: 10
      documento.text "#{texto(item[:local])} | #{texto(item[:metodo_nome])}", size: 9
      documento.move_down 8
      documento.stroke_horizontal_rule
      documento.move_down 8
    end

    Resultado.new(conteudo: documento.render,
                  nome_arquivo: "historico_#{usuario.matricula}.pdf",
                  tipo_mime: "application/pdf", lancamentos: lancamentos)
  end

  # As fontes nativas do Prawn usam Windows-1252. Substituir caracteres fora
  # desse alfabeto evita que um cadastro impeça a exportação.
  def self.texto(valor)
    valor.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").encode("UTF-8")
  end
  private_class_method :texto
end
