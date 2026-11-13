class ExtratoRefeicoesController < ApplicationController
  before_action :exigir_usuario
  rescue_from ArgumentError, with: :filtro_invalido

  def index
    acessos = usuario_atual.historico_refeicoes.includes(catraca: :restaurante)
    recargas = usuario_atual.extrato_recargas.concluida
    agora = Time.current.in_time_zone("America/Sao_Paulo")
    mes = agora.beginning_of_month..agora.end_of_month
    @gasto_mes = acessos.where(passagem_em: mes).sum(:valor_debitado)
    @refeicoes_mes = acessos.where(passagem_em: mes).where.not(passagem_em: nil).count
    @recarga_mes = recargas.where(data_hora: mes).sum(:valor)
    @quantidade_recargas_mes = recargas.where(data_hora: mes).count
    @turnos = Turno.order(:inicio)
    @restaurantes = Restaurante.order(:nome)

    @periodo = params[:periodo].presence_in(%w[30 mes todos]) || "30"
    registros = HistoricoEstudanteService.call(usuario: usuario_atual, filtros: filtros_historico)
    @total = registros.size
    @por_pagina = params[:por_pagina].to_i.presence_in([5, 10, 20]) || 5
    @paginas = [(@total.to_f / @por_pagina).ceil, 1].max
    @pagina = params[:pagina].to_i.clamp(1, @paginas)
    @inicio = (@pagina - 1) * @por_pagina
    @lancamentos = registros.slice(@inicio, @por_pagina) || []
  end

  def exportar
    resultado = ExportacaoHistoricoPdfService.call(usuario: usuario_atual, filtros: filtros_historico)
    send_data resultado.conteudo, filename: resultado.nome_arquivo,
              type: resultado.tipo_mime, disposition: "attachment"
  end

  private

  def filtros_historico
    params.permit(:periodo, :mes_referencia, :evento, :restaurante_id, :metodo).to_h
  end

  def filtro_invalido(erro)
    render plain: "Filtro inválido: #{erro.message}", status: :bad_request
  end

  def exigir_usuario
    return redirect_to login_path unless usuario_atual
    head :forbidden unless usuario_atual.estudante?
  end
end
