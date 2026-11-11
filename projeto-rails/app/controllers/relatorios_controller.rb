# app/controllers/relatorios_controller.rb (ou adicione ao controller existente)
class RelatoriosController < ApplicationController
  before_action :authenticate_usuario!
  before_action :exigir_administrador!

  def global
    @data_hoje = Date.current
    @restaurantes = Restaurante.includes(:catracas).order(:nome)
    
    # KPIs baseados no banco de dados com o join correto da catraca
    @total_acessos = Acesso.where.not(passagem_em: nil).count
    @arrecadacao_global = Acesso.where.not(passagem_em: nil).sum(:valor_debitado)
    @total_fastpass = Acesso.where.not(passagem_em: nil).joins(:catraca).where(catracas: { modo_acesso: 'fastpass' }).count
    
    # Distribuição por turnos
    @turnos = Turno.includes(:acessos).order(:inicio)
  end

  private

  def exigir_administrador!
    unless current_usuario&.administrador?
      redirect_to root_path, alert: "Acesso restrito a administradores."
    end
  end
end
