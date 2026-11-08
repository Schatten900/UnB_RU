
require "bcrypt"

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
  validates :senha_hash, presence: true
  validates :saldo, numericality: { greater_than_or_equal_to: 0 }

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

  def saldo_suficiente_para?(turno)
    saldo >= turno.preco
  end

  def extrato_recargas
    recargas
  end

  def historico_refeicoes
    acessos.where.not(passagem_em: nil).includes(:turno)
  end

  def saldo_pendente
    recargas.pendente.sum(:valor)
  end

  def senha=(valor)
    return if valor.blank?

    self.senha_hash = BCrypt::Password.create(valor)
  end

  def senha_correta?(valor)
    return false if valor.blank? || senha_hash.blank?

    BCrypt::Password.new(senha_hash) == valor
  rescue BCrypt::Errors::InvalidHash
    false
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
