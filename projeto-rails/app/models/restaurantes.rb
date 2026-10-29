class Restaurante < ApplicationRecord

    has_many :catracas
    has_many :usuarios

    validates :nome, presence: true

end