class ExtratoRefeicoesController < ApplicationController
  before_action :exigir_estudante

  rescue_from ArgumentError do |erro|
    redirect_to student_extrato_refeicoes_path, alert: erro.message
  end

  def index
    extrato = ExtratoRefeicoesService.call(usuario: usuario_atual, filtros: parametros_filtros)
    @filtros = extrato.filtros
    @periodo = @filtros.fetch("periodo")
    @restaurantes = Restaurante.order(:nome)
    @gasto_mes = extrato.resumo.fetch(:gasto_mes)
    @refeicoes_mes = extrato.resumo.fetch(:refeicoes_mes)
    @recarga_mes = extrato.resumo.fetch(:recarga_mes)
    @quantidade_recargas_mes = extrato.resumo.fetch(:quantidade_recargas_mes)

    @total = extrato.lancamentos.size
    @por_pagina = tamanho_pagina
    @paginas = [(@total.to_f / @por_pagina).ceil, 1].max
    @pagina = params[:pagina].to_i.clamp(1, @paginas)
    @inicio = (@pagina - 1) * @por_pagina
    @lancamentos = extrato.lancamentos.slice(@inicio, @por_pagina) || []
  end

  def exportar
    documento = ExportacaoHistoricoPdfService.call(usuario: usuario_atual, filtros: parametros_filtros)
    send_data documento.conteudo, filename: documento.nome_arquivo,
              type: documento.tipo_mime, disposition: "attachment"
  end

  def recibo
    @lancamento = case params[:tipo]
    when "refeicao"
      acesso = usuario_atual.historico_refeicoes.includes(catraca: :restaurante).find(params[:id])
      ExtratoRefeicoesService.lancamento_refeicao(acesso)
    when "recarga"
      recarga = usuario_atual.extrato_recargas.concluida.find(params[:id])
      ExtratoRefeicoesService.lancamento_recarga(recarga)
    else
      raise ActiveRecord::RecordNotFound
    end
    @filtros = ExtratoRefeicoesService.normalizar_filtros(parametros_filtros)
    @pagina = [params[:pagina].to_i, 1].max
    @por_pagina = tamanho_pagina

    respond_to do |format|
      format.html
      format.pdf do
        documento = GeradorPdfHistorico.call(
          usuario: usuario_atual, lancamentos: [@lancamento], titulo: "Comprovante de lançamento"
        )
        send_data documento.conteudo,
                  filename: "comprovante_#{@lancamento[:tipo]}_#{@lancamento[:registro_id]}.pdf",
                  type: documento.tipo_mime, disposition: "attachment"
      end
    end
  end

  private

  def exigir_estudante
    return if usuario_atual&.estudante?

    redirect_to login_path, alert: "Acesso restrito a estudantes."
  end

  def parametros_filtros
    params.permit(*ExtratoRefeicoesService::FILTROS).to_h
  end

  def tamanho_pagina
    params[:por_pagina].to_i.presence_in([5, 10, 20]) || 5
  end
end
