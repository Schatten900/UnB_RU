class Restaurante < ApplicationRecord
  has_many :catracas, dependent: :restrict_with_error
  has_many :usuarios

  validates :nome, presence: true
end
