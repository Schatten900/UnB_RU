class Sorteio < ApplicationRecord

  has_many :inscricoes_fastpass

  validates :data, presence: true
  validates :status, presence: true

end
