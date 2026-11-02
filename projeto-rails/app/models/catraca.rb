class Catraca < ApplicationRecord
  belongs_to :restaurante

  validates :piso, presence: true
  validates :modo_acesso, inclusion: { in: %w[normal fastpass] }
end
