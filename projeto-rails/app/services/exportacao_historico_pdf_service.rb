class ExportacaoHistoricoPdfService
  def self.call(usuario:, filtros: {}, mes: nil, ano: nil, gerador_pdf: GeradorHistoricoPdf)
    raise ArgumentError, "Estudante não informado" if usuario&.matricula.blank?

    filtros = filtros.to_h.stringify_keys
    if mes || ano
      referencia = Date.new(Integer(ano), Integer(mes), 1)
      filtros["mes_referencia"] = referencia.strftime("%Y-%m")
    end
    lancamentos = HistoricoEstudanteService.call(usuario: usuario, filtros: filtros)
    gerador_pdf.call(usuario: usuario, lancamentos: lancamentos)
  end
end
