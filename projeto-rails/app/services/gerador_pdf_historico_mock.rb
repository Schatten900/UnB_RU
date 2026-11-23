# Temporary adapter for the backend phase. It deliberately does NOT generate a PDF.
# The integration phase can replace this class with an actual PDF renderer.
class GeradorPdfHistoricoMock
  Resultado = Struct.new(
    :simulado, :nome_arquivo, :tipo_mime, :conteudo, :lancamentos,
    keyword_init: true
  )

  def self.call(usuario:, lancamentos:)
    Resultado.new(
      simulado: true,
      nome_arquivo: "historico_#{usuario.matricula}_mock.txt",
      tipo_mime: "text/plain",
      conteudo: "Exportacao simulada - nenhum PDF foi gerado.\n" \
                "Matricula: #{usuario.matricula}\n" \
                "Total de lancamentos: #{lancamentos.size}\n",
      lancamentos: lancamentos
    )
  end
end
