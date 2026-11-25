# Apresenta o extrato, o histórico e os comprovantes do estudante autenticado
#
# Restringe as consultas à própria conta e oferece exportação em PDF
class ExtratoRefeicoesController < ApplicationController
  before_action :exigir_estudante

  rescue_from ArgumentError do |erro|
    if action_name == "exportar" || params[:mes_referencia].present?
      render plain: "Filtro inválido: #{erro.message}", status: :bad_request
    else
      redirect_to student_extrato_refeicoes_path, alert: erro.message
    end
  end

  # Exibe o extrato filtrado, o resumo mensal e os lançamentos da pagina solicitada
  #
  # Usa os filtros permitidos da requisição e disponibiliza os dados para a view.
  def index
    extrato = ExtratoRefeicoesService.call(usuario: usuario_atual, filtros: parametros_filtros)

    carregar_filtros_extrato(extrato)
    carregar_resumo_extrato(extrato.resumo)
    paginar_lancamentos(extrato.lancamentos)
  end

  # Envia como anexo o PDF de todos os lançamentos que atendem aos filtros.
  #
  # A exportação usa a conta autenticada e independe da página exibida na tela.
  # Erros de argumentos são tratados pelo rescue_from do controller.
  def exportar
    documento = ExportacaoHistoricoPdfService.call(usuario: usuario_atual, filtros: parametros_filtros)
    send_data documento.conteudo, filename: documento.nome_arquivo,
              type: documento.tipo_mime, disposition: "attachment"
  end

  # Exibe ou envia em PDF o comprovante de um lançamento da própria conta.
  #
  # Parâmetros da requisição:
  # - +tipo+: "refeicao" para passagem confirmada ou "recarga" para crédito concluído.
  # - +id+: identificador do registro correspondente.
  # - +pagina+ e +por_pagina+: estado de navegação para retornar ao extrato.
  # - +format+: HTML para exibição ou PDF para download.
  #
  # Normaliza os filtros permitidos para preservar o retorno ao extrato.
  # Lança ActiveRecord::RecordNotFound se o tipo for inválido ou o registro
  # não pertencer às coleções autorizadas do estudante autenticado.
  def recibo
    @lancamento = localizar_lancamento_recibo
    carregar_retorno_recibo

    respond_to do |format|
      format.html
      format.pdf { enviar_recibo_pdf }
    end
  end

  private

  # Retorna o lançamento solicitado, restrito à conta autenticada.
  # Lança ActiveRecord::RecordNotFound para tipos ou registros inválidos.
  def localizar_lancamento_recibo
    case params[:tipo]
    when "refeicao"
      acesso = usuario_atual.historico_refeicoes.includes(catraca: :restaurante).find(params[:id])
      ExtratoRefeicoesService.lancamento_refeicao(acesso)
    when "recarga"
      recarga = usuario_atual.extrato_recargas.concluida.find(params[:id])
      ExtratoRefeicoesService.lancamento_recarga(recarga)
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  # Preserva os filtros e a paginação para retornar ao extrato.
  def carregar_retorno_recibo
    @filtros = ExtratoRefeicoesService.normalizar_filtros(parametros_filtros)
    @pagina = [params[:pagina].to_i, 1].max
    @por_pagina = tamanho_pagina
  end

  # Gera e envia o comprovante do lançamento como anexo PDF.
  def enviar_recibo_pdf
    documento = GeradorPdfHistorico.call(
      usuario: usuario_atual, lancamentos: [@lancamento], titulo: "Comprovante de lançamento"
    )
    send_data documento.conteudo,
              filename: nome_arquivo_recibo,
              type: documento.tipo_mime,
              disposition: "attachment"
  end

  # Retorna o nome do PDF usando o tipo e o identificador do lançamento.
  def nome_arquivo_recibo
    "comprovante_#{@lancamento[:tipo]}_#{@lancamento[:registro_id]}.pdf"
  end

  # Disponibiliza os filtros de +extrato+ e os restaurantes para a view.
  def carregar_filtros_extrato(extrato)
    @filtros = extrato.filtros
    @periodo = @filtros.fetch("periodo")
    @restaurantes = Restaurante.order(:nome)
  end

  # Disponibiliza os indicadores mensais presentes no Hash +resumo+.
  def carregar_resumo_extrato(resumo)
    @gasto_mes = resumo.fetch(:gasto_mes)
    @refeicoes_mes = resumo.fetch(:refeicoes_mes)
    @recarga_mes = resumo.fetch(:recarga_mes)
    @quantidade_recargas_mes = resumo.fetch(:quantidade_recargas_mes)
  end

  # Seleciona a página de +lancamentos+, já filtrados e ordenados pelo serviço.
  #
  # Limita a página ao intervalo disponível e mantém uma página no estado vazio.
  # Disponibiliza os registros e os dados de paginação nas variáveis da view.
  def paginar_lancamentos(lancamentos)
    @total = lancamentos.size
    @por_pagina = tamanho_pagina
    @paginas = [(@total.to_f / @por_pagina).ceil, 1].max
    @pagina = params[:pagina].to_i.clamp(1, @paginas)
    @inicio = (@pagina - 1) * @por_pagina
    @lancamentos = lancamentos.slice(@inicio, @por_pagina) || []
  end

  # Permite as ações somente para estudante autenticado.
  #
  # Retorna HTTP 403 na exportação solicitada por outro perfil autenticado;
  # nos demais casos sem permissão, redireciona ao login e interrompe a ação.
  def exigir_estudante
    return if usuario_atual&.estudante?

    if usuario_atual && action_name == "exportar"
      head :forbidden
    else
      redirect_to login_path, alert: "Acesso restrito a estudantes."
    end
  end

  # Retorna um Hash com apenas os filtros aceitos pelo ExtratoRefeicoesService.
  def parametros_filtros
    params.permit(*ExtratoRefeicoesService::FILTROS).to_h
  end

  # Retorna o tamanho de página solicitado quando for 5, 10 ou 20; senão, retorna 5.
  def tamanho_pagina
    params[:por_pagina].to_i.presence_in([5, 10, 20]) || 5
  end
end
