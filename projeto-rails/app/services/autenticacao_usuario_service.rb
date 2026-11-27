##
# Serviço responsável pela autenticação dos usuários que não
# possuem perfil de funcionário.
#
# Verifica a existência da conta, o perfil do usuário e a validade
# da senha informada.
#
class AutenticacaoUsuarioService
  ##
  # Autentica um usuário a partir de sua matrícula e senha,
  # desconsiderando contas identificadas como funcionários.
  #
  # Localiza o usuário pela matrícula e verifica se ele existe,
  # se seu perfil não corresponde a funcionário e se a senha
  # informada está correta.
  #
  # @param matricula [String] Matrícula utilizada para localizar
  #   a conta do usuário.
  # @param senha [String] Senha informada durante o login.
  #
  # @return [Usuario, nil] Retorna o usuário autenticado quando
  #   ele existe, não possui perfil de funcionário e informou
  #   a senha correta. Retorna nil caso alguma dessas condições
  #   não seja satisfeita.
  #
  # Efeito colateral: Realiza uma consulta ao banco de dados
  # e verifica a senha do usuário. Não cria nem modifica
  # a sessão de autenticação.
  def self.call(matricula:, senha:)
    usuario = Usuario.find_by(matricula: matricula)

    return nil unless usuario
    return nil if usuario.perfil.to_s.casecmp('funcionario').zero?
    return nil unless usuario.senha_correta?(senha)

    usuario
  end
end
