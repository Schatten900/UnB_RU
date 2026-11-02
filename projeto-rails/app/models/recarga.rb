class Recarga < ApplicationRecord
  belongs_to :usuario, foreign_key: :usuario_matricula, primary_key: :matricula
end
