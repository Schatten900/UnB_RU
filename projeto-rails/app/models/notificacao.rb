class Notificacao < ApplicationRecord
  self.table_name = "notificacoes"

  belongs_to :usuario,
    foreign_key: :usuario_matricula,
    primary_key: :matricula

  validates :mensagem, presence: true
end