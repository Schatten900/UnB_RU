class ExportacaoHistoricoPdfService
  def self.call(usuario:, mes: nil, ano: nil, filtros: {}, gerador_pdf: GeradorHistoricoPdf,
                recargas_model: nil, acessos_model: nil)
    raise ArgumentError, "Estudante não informado" if usuario&.matricula.blank?

    # Compatibilidade com os consumidores que injetam modelos de consulta.
    if recargas_model || acessos_model
      return exportar_com_modelos(usuario: usuario, mes: mes, ano: ano,
        gerador_pdf: gerador_pdf, recargas_model: recargas_model || Recarga,
        acessos_model: acessos_model || Acesso)
    end

    filtros = filtros.to_h.stringify_keys
    if mes || ano
      referencia = Date.new(Integer(ano), Integer(mes), 1)
      filtros["mes_referencia"] = referencia.strftime("%Y-%m")
    end
    extrato = ExtratoRefeicoesService.call(usuario: usuario, filtros: filtros)
    gerador_pdf.call(usuario: usuario, lancamentos: extrato.lancamentos)
  end

  def self.exportar_com_modelos(usuario:, mes:, ano:, gerador_pdf:, recargas_model:, acessos_model:)
    data_inicial = Date.new(Integer(ano), Integer(mes), 1)
    inicio = data_inicial.in_time_zone
    fim = data_inicial.next_month.in_time_zone
    matricula = usuario.matricula

    recargas = recargas_model.where(
      usuario_matricula: matricula, data_hora: inicio...fim, status: "concluida"
    )

    registros_acesso = acessos_model.where(
      usuario_matricula: matricula, passagem_em: inicio...fim
    )

    lancamentos = recargas.map do |recarga|
      { tipo: "recarga", data_hora: recarga.data_hora, valor: recarga.valor }
    end

    lancamentos.concat(registros_acesso.map do |acesso|
      {
        tipo: "acesso",
        data_hora: acesso.passagem_em,
        valor: acesso.valor_debitado,
        status: acesso.status
      }
    end)

    lancamentos.sort_by! { |item| [item[:data_hora], item[:tipo]] }

    gerador_pdf.call(usuario: usuario, lancamentos: lancamentos)
  end
  private_class_method :exportar_com_modelos
end
