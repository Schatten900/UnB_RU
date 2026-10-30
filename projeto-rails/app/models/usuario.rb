require "bcrypt"

class Usuario < ApplicationRecord

    self.primary_key = "matricula"

    belongs_to :turno, optional:true
    belongs_to :restaurante, optional:true

    validates :nome, presence: true
    validates :senha_hash, presence: true
    validates :perfil, presence: true
    validates :saldo, numericality: {greater_than_or_equal_to: 0}

    
    # recebe a senha digitada e armazena seu hash
    def senha=(valor)
        return if valor.blank?

        self.senha_hash = BCrypt::Password.create(valor)
    end


    # Confere a senha informada com o hash armazenado.
    def senha_correta?(valor)
        return false if valor.blank? || senha_hash.blank?

        BCrypt::Password.new(senha_hash) == valor

    rescue BCrypt::Errors::InvalidHash
        false
    end


    # Confere o perfil e o prefixo da matrícula.
    def funcionario?
        perfil.to_s.casecmp("funcionario").zero? && matricula.to_s.match?(/\A999\d{6}\z/)
    end

end
