
##
# Serviço responsável pela autenticação de usuários com perfil
# de funcionário.
#
# Verifica a existência da conta, o perfil de funcionário,
# a validade da senha e se o horário atual está dentro do turno
# associado ao usuário.
#
class AutenticacaoFuncionarioService

    ##
    # Autentica um funcionário considerando suas credenciais
    # e o horário permitido para seu turno.
    #
    # Localiza o usuário pela matrícula e verifica seu perfil,
    # a validade da senha e a compatibilidade do horário informado
    # com o turno cadastrado.
    #
    # @param matricula [String] Matrícula utilizada para localizar
    #   a conta do funcionário.
    # @param senha [String] Senha informada durante o login.
    # @param agora [Time] Horário utilizado para verificar se
    #   o acesso está dentro do turno permitido. Por padrão,
    #   utiliza Time.current.
    #
    # @return [Usuario, nil] Retorna o usuário autenticado quando
    #   todas as condições são satisfeitas. Retorna nil caso
    #   o usuário não exista, não seja funcionário, a senha esteja
    #   incorreta ou o horário esteja fora do turno permitido.
    #
    # Efeito colateral: Realiza consultas ao banco de dados
    # e verifica a senha e o turno do funcionário. Não cria
    # nem modifica a sessão de autenticação.
    def self.call(matricula:, senha:, agora: Time.current)
        usuario = Usuario.find_by(matricula: matricula)

        return nil unless usuario
        return nil unless usuario.funcionario?
        return nil unless usuario.senha_correta?(senha)
        return nil unless horario_permitido?(usuario, agora)

        usuario
    end

    ##
    # Verifica se o horário informado está dentro do turno
    # associado ao funcionário.
    #
    # Considera o fuso horário de Brasília e contempla turnos
    # que atravessam a meia-noite.
    #
    # @param usuario [Usuario] Usuário cujo turno será utilizado
    #   na verificação.
    # @param agora [Time] Horário utilizado como referência
    #   para verificar a permissão de acesso.
    #
    # @return [Boolean] Retorna true quando o horário está dentro
    #   do turno permitido. Retorna false quando o usuário não possui
    #   turno, os horários do turno não estão definidos ou o horário
    #   informado está fora do intervalo permitido.
    #
    # Efeito colateral: Pode acessar a associação de turno do usuário,
    # realizando consulta ao banco de dados caso ela não esteja
    # previamente carregada. Não modifica registros.
    def self.horario_permitido?(usuario, agora)
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

    # Restringe o acesso ao método de verificação de horário
    # ao próprio serviço de autenticação.
    private_class_method :horario_permitido?
end
