
class Recarga < ApplicationRecord
  belongs_to :usuario,
    foreign_key: :usuario_matricula,
    primary_key: :matricula

  enum :metodo, {
    pix: "PIX",
    cartao_credito: "cartao_credito"
  }

  enum :status, {
    pendente: "pendente",
    concluida: "concluida",
    falhou: "falhou"
  }

  validates :valor,
    numericality: { greater_than: 0 }

  validates :metodo, presence: true
end
#AI: chatGPT desktop, no think
#Prompt and strategy: First, we warmed GPT up by asking for file structure given the proposed feature, then we asked for a code with our project's specs, this was consolidated with other .rb

