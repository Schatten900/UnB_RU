# Mantém o contrato de exportação da sprint-2 usando o mesmo gerador dos recibos.
class GeradorHistoricoPdf
  def self.call(usuario:, lancamentos:)
    documento = GeradorPdfHistorico.call(usuario: usuario, lancamentos: lancamentos)
    documento.nome_arquivo = "historico_#{usuario.matricula}.pdf"
    documento
  end
end
