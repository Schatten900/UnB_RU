class ExportacaoHistoricoPdfService
  # Exporta o histórico do usuário conforme filtros ou mês/ano recebidos.
  # Aceita gerador e modelos opcionais; retorna o documento gerado e consulta o banco.
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

  # Consulta recargas e passagens do usuário no mês/ano usando os modelos recebidos.
  # Retorna o documento do gerador recebido; consulta o banco sem gravar.
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

    lancamentos = lancamentos_recargas(recargas) + lancamentos_acessos(registros_acesso)
    lancamentos.sort_by! { |item| [item[:data_hora], item[:tipo]] }

    gerador_pdf.call(usuario: usuario, lancamentos: lancamentos)
  end

  # Converte a coleção de recargas recebida em lançamentos financeiros.
  # Retorna Array de Hash; pode carregar a consulta, sem alterar registros.
  def self.lancamentos_recargas(recargas)
    recargas.map do |recarga|
      { tipo: "recarga", data_hora: recarga.data_hora, valor: recarga.valor }
    end
  end

  # Converte a coleção de acessos recebida em lançamentos financeiros.
  # Retorna Array de Hash; pode carregar a consulta, sem alterar registros.
  def self.lancamentos_acessos(acessos)
    acessos.map do |acesso|
      { tipo: "acesso", data_hora: acesso.passagem_em,
        valor: acesso.valor_debitado, status: acesso.status }
    end
  end
  private_class_method :exportar_com_modelos, :lancamentos_recargas, :lancamentos_acessos
end
