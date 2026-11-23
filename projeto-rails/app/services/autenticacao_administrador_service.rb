class AutenticacaoAdministradorService
    def self.call(matricula:, senha:)
        usuario = Usuario.find_by(matricula: matricula)

        return nil unless usuario&.administrador?
        return nil unless usuario.senha_correta?(senha)

        usuario
    end
end