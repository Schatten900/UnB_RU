class Cardapio < ApplicationRecord
  belongs_to :turno

  validates :data, presence: true
  validates :opcao_padrao, presence: true
  validates :opcao_ovolactovegetariana, presence: true
  validates :opcao_vegetariana_estrita, presence: true

  validates :data, uniqueness: { scope: :turno_id }
end