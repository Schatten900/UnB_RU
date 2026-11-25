
##
# Serviço responsável pela autenticação de usuários com perfil
# de administrador.
#
# Verifica a existência da conta, o perfil administrativo
# e a validade da senha informada.
#
class AutenticacaoAdministradorService

    ##
    # Autentica um administrador a partir de sua matrícula e senha.
    #
    # Localiza o usuário pela matrícula e verifica se ele possui
    # perfil de administrador e se a senha informada está correta.
    #
    # @param matricula [String] Matrícula utilizada para localizar
    #   a conta do administrador.
    # @param senha [String] Senha informada durante o login.
    #
    # @return [Usuario, nil] Retorna o usuário autenticado caso
    #   exista, possua perfil de administrador e tenha informado
    #   a senha correta. Retorna nil caso alguma dessas condições
    #   não seja satisfeita.
    #
    # Efeito colateral: Realiza uma consulta ao banco de dados
    # e verifica a senha do usuário. Não cria nem modifica
    # a sessão de autenticação.
    def self.call(matricula:, senha:)
        usuario = Usuario.find_by(matricula: matricula)

        return nil unless usuario&.administrador?
        return nil unless usuario.senha_correta?(senha)

        usuario
    end
end
