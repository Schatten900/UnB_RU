
class Usuario < ApplicationRecord
  self.primary_key = :matricula

  has_many :recargas,
    foreign_key: :usuario_matricula,
    primary_key: :matricula,
    dependent: :destroy

  has_many :acessos,
    foreign_key: :usuario_matricula,
    primary_key: :matricula

  belongs_to :turno, optional: true
  belongs_to :restaurante, optional: true

  validates :matricula,
    presence: true,
    uniqueness: true,
    format: { with: /\A\d{9}\z/ }

  validates :nome, presence: true

  before_validation :definir_perfil

  def administrador?
    matricula.to_s.start_with?("9999")
  end

  def funcionario?
    matricula.to_s.start_with?("999") && !administrador?
  end

  def estudante?
    !funcionario? && !administrador?
  end

  def extrato_recargas
    recargas
  end

  def historico_refeicoes
    acessos.includes(:turno)
  end

  def saldo_pendente
    recargas.pendente.sum(:valor)
  end

  private

  def definir_perfil
    self.perfil =
      if administrador?
        "administrador"
      elsif funcionario?
        "funcionario"
      else
        "estudante"
      end
  end
end



#AI: GPT desktop, no think
#Prompt and strategy: First, we warmed GPT up by asking for file structure given the proposed feature, then we asked for a code with our project's specs, this was consolidated with other .rb
