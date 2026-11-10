class ExtratoRefeicoesController < ApplicationController
  before_action :exigir_usuario

  def index
    acessos = usuario_atual.historico_refeicoes.includes(catraca: :restaurante)
    recargas = usuario_atual.extrato_recargas.concluida
    agora = Time.current.in_time_zone("America/Sao_Paulo")
    mes = agora.beginning_of_month..agora.end_of_month
    @gasto_mes = acessos.where(data_hora: mes).sum(:valor_debitado)
    @refeicoes_mes = acessos.where(data_hora: mes).where.not(passagem_em: nil).count
    @recarga_mes = recargas.where(data_hora: mes).sum(:valor)
    @quantidade_recargas_mes = recargas.where(data_hora: mes).count
    @turnos = Turno.order(:inicio)
    @restaurantes = Restaurante.order(:nome)

    @periodo = params[:periodo].presence_in(%w[30 mes todos]) || "30"
    inicio = case @periodo
    when "30" then (agora - 29.days).beginning_of_day
    when "mes" then agora.beginning_of_month
    end
    if inicio
      acessos = acessos.where(data_hora: inicio..agora)
      recargas = recargas.where(data_hora: inicio..agora)
    end

    registros = acessos.map do |acesso|
      {
        id: "acesso-#{acesso.id}", data_hora: acesso.data_hora,
        tipo: "refeicao", nome: acesso.turno.nome, turno_id: acesso.turno_id,
        restaurante_id: acesso.catraca.restaurante_id,
        local: "#{acesso.catraca.restaurante.nome} · Piso #{acesso.catraca.piso}",
        detalhe: "Catraca #{acesso.catraca_id} · #{acesso.status.humanize}",
        metodo: acesso.inscricao_fastpass_id ? "fastpass" : "comum",
        metodo_nome: acesso.inscricao_fastpass_id ? "FastPass" : "Comum",
        valor: acesso.valor_debitado
      }
    end
    registros.concat(recargas.map do |recarga|
      {
        id: "recarga-#{recarga.id}", data_hora: recarga.data_hora,
        tipo: "recarga", nome: "Recarga de Saldo",
        local: recarga.pix? ? "Pagamento via PIX" : "Pagamento via cartão",
        detalhe: "Recarga concluída", metodo: recarga.metodo,
        metodo_nome: recarga.pix? ? "PIX" : "Cartão de crédito", valor: recarga.valor
      }
    end)
    registros.select! { |item| item[:tipo] == "recarga" } if params[:evento] == "recarga"
    if params[:evento].to_s.start_with?("turno:")
      registros.select! { |item| item[:turno_id].to_s == params[:evento].delete_prefix("turno:") }
    end
    if params[:restaurante_id].present?
      registros.select! { |item| item[:restaurante_id].to_s == params[:restaurante_id] }
    end
    registros.select! { |item| item[:metodo] == params[:metodo] } if params[:metodo].present?
    registros.sort_by! { |item| [item[:data_hora], item[:id]] }.reverse!
    @total = registros.size
    @por_pagina = params[:por_pagina].to_i.presence_in([5, 10, 20]) || 5
    @paginas = [(@total.to_f / @por_pagina).ceil, 1].max
    @pagina = params[:pagina].to_i.clamp(1, @paginas)
    @inicio = (@pagina - 1) * @por_pagina
    @lancamentos = registros.slice(@inicio, @por_pagina) || []
  end

  private

  def exigir_usuario
    redirect_to login_path unless usuario_atual
  end
end
