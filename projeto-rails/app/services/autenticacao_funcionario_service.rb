class AutenticacaoFuncionarioService

    # Adquire o turno vinculado ao  horario 
    def self.call(matricula:, senha:, agora: Time.current)
        usuario = Usuario.find_by(matricula: matricula)

        return nil unless usuario
        return nil unless usuario.funcionario?
        return nil unless usuario.senha_correta?(senha)
        return nil unless horario_permitido?(usuario,agora)

        return usuario
    end

    def self.horario_permitido?(usuario,agora)
        return false unless usuario.turno

        inicio = usuario.turno.inicio
        fim = usuario.turno.fim

        return false unless inicio && fim 

        horario_atual = agora.in_time_zone("America/Sao_Paulo").seconds_since_midnight
        inicio_segundos = inicio.seconds_since_midnight
        fim_segundos = fim.seconds_since_midnight

        if inicio_segundos <= fim_segundos
            horario_atual >= inicio_segundos && horario_atual <= fim_segundos
        else
            horario_atual >= inicio_segundos || horario_atual <= fim_segundos
        end
    end

    # metodo privado para buscar turno
    private_class_method :horario_permitido?

end