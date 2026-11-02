class Usuario < ApplicationRecord
  self.primary_key = :matricula

  has_many :recargas, foreign_key: :usuario_matricula, primary_key: :matricula
  has_many :acessos, foreign_key: :usuario_matricula, primary_key: :matricula

  def extrato_recargas
    recargas
  end

  def historico_refeicoes
    acessos.includes(:turno)
  end
end
