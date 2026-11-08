#models/acesso.rb
class Acesso < ApplicationRecord
  belongs_to :usuario, foreign_key: :usuario_matricula, primary_key: :matricula
  belongs_to :turno
  belongs_to :catraca
end
