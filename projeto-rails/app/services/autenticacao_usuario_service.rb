class AutenticacaoUsuarioService

    def self.call(matricula:, senha:)
        usuario = Usuario.find_by(matricula: matricula)

        return nil unless usuario
        return nil if usuario.perfil.to_s.casecmp("funcionario").zero?
        return nil unless usuario.senha_correta?(senha)

        return usuario
    end

end