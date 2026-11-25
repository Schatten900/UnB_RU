# Mantém o contrato de exportação da sprint-2 usando o mesmo gerador dos recibos.
class GeradorHistoricoPdf
  # Gera o PDF do usuário e dos lançamentos recebidos com o nome de download do histórico.
  # Retorna o documento e ajusta seu nome em memória, sem gravar no banco.
  def self.call(usuario:, lancamentos:)
    documento = GeradorPdfHistorico.call(usuario: usuario, lancamentos: lancamentos)
    documento.nome_arquivo = "historico_#{usuario.matricula}.pdf"
    documento
  end
end
