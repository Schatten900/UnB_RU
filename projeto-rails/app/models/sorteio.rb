class Sorteio < ApplicationRecord

  has_many :inscricoes_fastpass

  validates :data, presence: true
  validates :status, presence: true

  self.table_name = "sorteios"
end
