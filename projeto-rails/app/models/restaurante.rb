class Restaurante < ApplicationRecord
  has_many :catracas, dependent: :restrict_with_error
  has_many :usuarios
  has_many :acessos, through: :catracas
  validates :nome, presence: true
end
