class HistoricoLocalController < ApplicationController
  REGISTROS_POR_PAGINA = 10
  STATUS_VALIDOS = %w[liberado bloqueado pendente].freeze
  VINCULOS_VALIDOS = %w[fastpass sem_vinculo].freeze

  before_action :exigir_funcionario
  before_action :carregar_catraca_configurada
  before_action :carregar_filtros

  # Exibe o histórico paginado e os indicadores da catraca configurada.
  # Lê os filtros da requisição; retorna HTML, consultando o banco e preparando a view.
  def index
    carregar_pagina(acessos_filtrados)
    carregar_indicadores
  end

  # Exporta todos os acessos filtrados em CSV ou PDF, sem paginação.
  # Lê formato e filtros da requisição; retorna download ou redirecionamento e consulta o banco.
  def exportar
    acessos = acessos_filtrados.includes(:usuario, :turno).to_a
    nome_base = "historico_catraca_#{@catraca.id}_#{Time.zone.today.iso8601}"

    case params[:formato].to_s.downcase
    when 'csv'
      enviar_csv(acessos, nome_base)
    when 'pdf'
      enviar_pdf(acessos, nome_base)
    else
      redirect_to operator_historico_local_path, alert: 'Formato de exportacao invalido.'
    end
  end

  private

  # Envia o CSV dos acessos com o nome informado.
  # Recebe acessos e nome_base; retorna a resposta de download, sem gravar no banco.
  def enviar_csv(acessos, nome_base)
    send_data Relatorios::HistoricoLocalExportacao.csv(acessos: acessos),
              filename: "#{nome_base}.csv", type: 'text/csv; charset=utf-8', disposition: 'attachment'
  end

  # Envia o PDF dos acessos da catraca configurada.
  # Recebe acessos e nome_base; retorna a resposta de download, sem gravar no banco.
  def enviar_pdf(acessos, nome_base)
    send_data Relatorios::HistoricoLocalExportacao.pdf(acessos: acessos, catraca: @catraca),
              filename: "#{nome_base}.pdf", type: 'application/pdf', disposition: 'attachment'
  end

  # Calcula a página válida para o escopo de acessos recebido.
  # Retorna o último índice exibido; consulta o banco e prepara as variáveis da view.
  def carregar_pagina(escopo)
    @total_registros = escopo.count
    @total_paginas = [(@total_registros.to_f / REGISTROS_POR_PAGINA).ceil, 1].max
    @pagina = params[:pagina].to_i.clamp(1, @total_paginas)
    carregar_registros(escopo)
  end

  # Carrega os registros da página a partir do escopo recebido.
  # Retorna o último índice exibido; consulta o banco e prepara a listagem.
  def carregar_registros(escopo)
    deslocamento = (@pagina - 1) * REGISTROS_POR_PAGINA
    @acessos = escopo.includes(:usuario, :turno).limit(REGISTROS_POR_PAGINA).offset(deslocamento).to_a
    @primeiro_registro = @total_registros.zero? ? 0 : deslocamento + 1
    @ultimo_registro = @primeiro_registro.zero? ? 0 : @primeiro_registro + @acessos.length - 1
  end

  # Calcula passagens, bloqueios e débitos do dia na catraca.
  # Sem argumentos; retorna a soma debitada e prepara indicadores consultando o banco.
  def carregar_indicadores
    todos = HistoricoLocalService.call(usuario: usuario_atual, catraca_id: @catraca.id)
    hoje = Time.zone.today.all_day
    confirmados = todos.where(passagem_em: hoje)
    @passagens_hoje = confirmados.count
    @bloqueios_hoje = todos.where(status: 'bloqueado', data_hora: hoje).count
    @valor_debitado_hoje = confirmados.sum(:valor_debitado)
  end

  # Verifica o funcionário e carrega a catraca indicada na sessão.
  # Sem argumentos; retorna nil ou redirecionamento; consulta o banco e prepara o contexto.
  def carregar_catraca_configurada
    # A tela US12 e destinada ao fiscal que opera um ponto configurado.
    unless usuario_atual&.funcionario?
      redirect_to operator_ponto_configuracao_path, alert: 'Historico local disponivel para funcionarios.'
      return
    end

    @catraca = Catraca.includes(:restaurante).find_by(
      id: session[:catraca_id], restaurante_id: session[:restaurante_id]
    )
    return if @catraca

    redirect_to operator_ponto_configuracao_path,
                alert: 'Configure um restaurante e uma catraca antes de consultar o historico.'
  end

  # Normaliza os filtros de status e vínculo recebidos na requisição.
  # Sem argumentos; retorna o vínculo válido ou nil e atualiza os filtros em memória.
  def carregar_filtros
    @status = params[:status].to_s
    @status = nil unless STATUS_VALIDOS.include?(@status)

    @vinculo = params[:vinculo].to_s
    @vinculo = nil unless VINCULOS_VALIDOS.include?(@vinculo)
  end

  # Monta a consulta do histórico da catraca com os filtros válidos.
  # Sem argumentos; retorna uma relação de Acesso, sem gravar no banco.
  def acessos_filtrados
    escopo = HistoricoLocalService.call(usuario: usuario_atual, catraca_id: @catraca.id)
    escopo = escopo.where(status: @status) if @status

    case @vinculo
    when 'fastpass'
      escopo = escopo.where.not(inscricao_fastpass_id: nil)
    when 'sem_vinculo'
      escopo = escopo.where(inscricao_fastpass_id: nil)
    end

    escopo
  end
end
