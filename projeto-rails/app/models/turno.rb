
class Turno < ApplicationRecord

    has_many :cardapios 
    has_many :usuarios

    validates :nome, presence: true
    validates :inicio, presence: true
    validates :fim, presence: true
    validates :preco, presence: true, numericality: {greater_than_or_equal_to: 0}
    
end