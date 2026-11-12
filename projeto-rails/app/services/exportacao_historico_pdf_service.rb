class ExportacaoHistoricoPdfService
  def self.call(usuario:, mes: nil, ano: nil, filtros: nil, gerador_pdf: GeradorPdfHistorico,
                recargas_model: Recarga, acessos_model: Acesso)
    raise ArgumentError, "Estudante nao informado" if usuario&.matricula.blank?

    if filtros
      extrato = ExtratoRefeicoesService.call(usuario: usuario, filtros: filtros)
      return gerador_pdf.call(usuario: usuario, lancamentos: extrato.lancamentos)
    end

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
end
