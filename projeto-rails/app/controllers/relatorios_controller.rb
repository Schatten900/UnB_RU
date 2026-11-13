# app/controllers/relatorios_controller.rb (ou adicione ao controller existente)

class RelatoriosController < ApplicationController
  before_action :authenticate_usuario!
  before_action :exigir_administrador!

  def global
    @data_hoje = Date.current

    # Todos os acessos efetivamente realizados desde o início da operação.
    @acessos_concluidos = Acesso.where.not(passagem_em: nil)

    @data_inicio_operacao = @acessos_concluidos.minimum(:passagem_em)

    @restaurantes = Restaurante.includes(:catracas).order(:nome)
    @turnos = Turno.order(:inicio)

    # Indicadores globais de todo o período.
    @total_acessos = @acessos_concluidos.count

    @arrecadacao_global = @acessos_concluidos.sum(:valor_debitado)

    # FastPass é identificado pela inscrição vinculada ao acesso.
    @total_fastpass = @acessos_concluidos
      .where.not(inscricao_fastpass_id: nil)
      .count

    @total_comum = @total_acessos - @total_fastpass

    @ticket_medio = if @total_acessos.positive?
      @arrecadacao_global / @total_acessos
    else
      0
    end

    # Quantidade de catracas cadastradas.
    @total_catracas = Catraca.count

    # Consolidação por restaurante.
    @estatisticas_restaurantes = {}

    dados_restaurantes = @acessos_concluidos
      .joins(:catraca)
      .group("catracas.restaurante_id")
      .pluck(
        "catracas.restaurante_id",
        Arel.sql("COUNT(acessos.id)"),
        Arel.sql("COUNT(acessos.inscricao_fastpass_id)"),
        Arel.sql("COALESCE(SUM(acessos.valor_debitado), 0)")
      )

    dados_restaurantes.each do |restaurante_id, acessos, fastpass, arrecadacao|
      @estatisticas_restaurantes[restaurante_id] = {
        acessos: acessos,
        fastpass: fastpass,
        arrecadacao: arrecadacao
      }
    end

    # Consolidação por turno.
    @estatisticas_turnos = {}

    dados_turnos = @acessos_concluidos
      .group(:turno_id)
      .pluck(
        :turno_id,
        Arel.sql("COUNT(acessos.id)"),
        Arel.sql("COALESCE(SUM(acessos.valor_debitado), 0)")
      )

    dados_turnos.each do |turno_id, acessos, arrecadacao|
      @estatisticas_turnos[turno_id] = {
        acessos: acessos,
        arrecadacao: arrecadacao
      }
    end
  end

  private

  def exigir_administrador!
    unless current_usuario&.administrador?
      redirect_to root_path, alert: "Acesso restrito a administradores."
    end
  end
end


#AI ChatGPT web
#Prompt and Strategy: provided pertinent files, asked help in natural language to integrate the relatorios part with the backend
