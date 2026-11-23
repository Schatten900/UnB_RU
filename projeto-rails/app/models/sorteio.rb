class Sorteio < ApplicationRecord

  has_many :inscricoes_fastpass, class_name: "InscricaoFastpass"

  validates :data, presence: true
  validates :status, presence: true

  self.table_name = "sorteios"

  def cotas_do_restaurante(restaurante)
    cotas.fetch(restaurante.id.to_s, {}).slice(*TimeFrame.pluck(:id).map(&:to_s))
  end
end
