class HistoricoLocalController < ApplicationController
  REGISTROS_POR_PAGINA = 10
  STATUS_VALIDOS = %w[liberado bloqueado pendente].freeze
  VINCULOS_VALIDOS = %w[fastpass sem_vinculo].freeze

  before_action :exigir_funcionario
  before_action :carregar_catraca_configurada
  before_action :carregar_filtros

  def index
    escopo = acessos_filtrados
    @total_registros = escopo.count
    @total_paginas = [(@total_registros.to_f / REGISTROS_POR_PAGINA).ceil, 1].max
    @pagina = [[params[:pagina].to_i, 1].max, @total_paginas].min

    @acessos = escopo.includes(:usuario, :turno)
                    .limit(REGISTROS_POR_PAGINA)
                    .offset((@pagina - 1) * REGISTROS_POR_PAGINA)
                    .to_a
    @primeiro_registro = @total_registros.zero? ? 0 : (@pagina - 1) * REGISTROS_POR_PAGINA + 1
    @ultimo_registro = @primeiro_registro.zero? ? 0 : @primeiro_registro + @acessos.length - 1

    # Indicadores de hoje, sem depender de equipamentos ou sistemas externos.
    todos = HistoricoLocalService.call(usuario: usuario_atual, catraca_id: @catraca.id)
    hoje = Time.zone.today.all_day
    confirmados_hoje = todos.where(passagem_em: hoje)
    @passagens_hoje = confirmados_hoje.count
    @bloqueios_hoje = todos.where(status: "bloqueado", data_hora: hoje).count
    @valor_debitado_hoje = confirmados_hoje.sum(:valor_debitado)
  end

  def exportar
    acessos = acessos_filtrados.includes(:usuario, :turno).to_a
    nome_base = "historico_catraca_#{@catraca.id}_#{Time.zone.today.iso8601}"

    case params[:formato].to_s.downcase
    when "csv"
      send_data Relatorios::HistoricoLocalExportacao.csv(acessos: acessos),
                filename: "#{nome_base}.csv",
                type: "text/csv; charset=utf-8",
                disposition: "attachment"
    when "pdf"
      send_data Relatorios::HistoricoLocalExportacao.pdf(acessos: acessos, catraca: @catraca),
                filename: "#{nome_base}.pdf",
                type: "application/pdf",
                disposition: "attachment"
    else
      redirect_to operator_historico_local_path, alert: "Formato de exportacao invalido."
    end
  end

  private

  def carregar_catraca_configurada
    # A tela US12 e destinada ao fiscal que opera um ponto configurado.
    unless usuario_atual&.funcionario?
      redirect_to operator_ponto_configuracao_path, alert: "Historico local disponivel para funcionarios."
      return
    end

    @catraca = Catraca.includes(:restaurante).find_by(
      id: session[:catraca_id], restaurante_id: session[:restaurante_id]
    )
    return if @catraca

    redirect_to operator_ponto_configuracao_path,
                alert: "Configure um restaurante e uma catraca antes de consultar o historico."
  end

  def carregar_filtros
    @status = params[:status].to_s
    @status = nil unless STATUS_VALIDOS.include?(@status)

    @vinculo = params[:vinculo].to_s
    @vinculo = nil unless VINCULOS_VALIDOS.include?(@vinculo)
  end

  def acessos_filtrados
    escopo = HistoricoLocalService.call(usuario: usuario_atual, catraca_id: @catraca.id)
    escopo = escopo.where(status: @status) if @status

    case @vinculo
    when "fastpass"
      escopo = escopo.where.not(inscricao_fastpass_id: nil)
    when "sem_vinculo"
      escopo = escopo.where(inscricao_fastpass_id: nil)
    end

    escopo
  end
end
