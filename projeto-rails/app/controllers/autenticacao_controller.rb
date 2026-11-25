
##
# Controller responsável pelo processo de autenticação dos usuários
# da aplicação, incluindo administradores, funcionários e estudantes.
#
# Gerencia a exibição da página de login, a validação das credenciais,
# a criação e o encerramento da sessão do usuário e os redirecionamentos
# de acordo com o perfil autenticado.
#
class AutenticacaoController < ApplicationController

    ##
    # Exibe a página de login caso não exista um usuário autenticado.
    #
    # Se já existir um usuário autenticado, redireciona para a página
    # inicial correspondente ao seu perfil.
    #
    # @return [String, ActionController::Metal::Redirecting] Resultado
    #   do redirecionamento ou da renderização da página de login.
    #
    # Efeito colateral: Pode realizar um redirecionamento ou renderizar
    # a página de login.
    def new
        return redirect_to pagina_inicial(usuario_atual) if usuario_atual

        render "sessoes/new"
    end

    ##
    # Processa a tentativa de autenticação do usuário.
    #
    # Obtém a matrícula e a senha informadas, remove espaços excedentes
    # da matrícula e encaminha as credenciais para o serviço de
    # autenticação correspondente ao prefixo da matrícula.
    #
    # Caso a autenticação seja bem-sucedida, reinicia a sessão,
    # armazena a matrícula do usuário autenticado e redireciona
    # para a página inicial correspondente ao seu perfil.
    #
    # Caso contrário, apresenta uma mensagem de falha de autenticação.
    # Também trata exceções relacionadas à indisponibilidade do banco
    # de dados.
    #
    # @return [ActionController::Metal::Redirecting,
    #   ActionController::Metal::Rendering] Resultado do redirecionamento
    #   ou da renderização da página de login.
    #
    # Efeito colateral: Pode reiniciar e modificar a sessão do usuário,
    # realizar consultas ao banco de dados, definir mensagens flash,
    # registrar erros no log e renderizar ou redirecionar a página.
    def create
        matricula = params[:matricula].to_s.strip
        usuario = autenticar(matricula)

        return falha_autenticacao unless usuario

        reset_session
        session[:usuario_matricula] = usuario.matricula

        redirect_to pagina_inicial(usuario),
                    notice: "Login realizado com sucesso."

    rescue ActiveRecord::ConnectionNotEstablished,
           ActiveRecord::ConnectionTimeoutError => e
        render_indisponibilidade(e)
    end

    ##
    # Encerra a sessão atual do usuário e redireciona para
    # a página de login.
    #
    # @return [ActionController::Metal::Redirecting] Resultado
    #   do redirecionamento para a página de login.
    #
    # Efeito colateral: Reinicia a sessão do usuário, removendo
    # os dados armazenados nela, e define uma mensagem flash
    # informando o encerramento da sessão.
    def destroy
        reset_session
        redirect_to login_path, notice: "Sessão encerrada."
    end

    private

    ##
    # Encaminha as credenciais para o serviço de autenticação
    # correspondente ao tipo de usuário identificado pela matrícula.
    #
    # Matrículas iniciadas por "9999" são encaminhadas para a
    # autenticação de administradores; matrículas iniciadas por
    # "999" são encaminhadas para a autenticação de funcionários;
    # as demais são encaminhadas para a autenticação de usuários.
    #
    # @param matricula [String] Matrícula informada no formulário
    #   de login, utilizada para identificar o tipo de usuário.
    #
    # @return [Usuario, nil] Retorna o usuário autenticado ou nil
    #   caso as credenciais ou as condições de autenticação sejam
    #   inválidas.
    #
    # @raise [ActiveRecord::ConnectionNotEstablished] Caso não seja
    #   possível estabelecer conexão com o banco de dados.
    # @raise [ActiveRecord::ConnectionTimeoutError] Caso ocorra
    #   um tempo limite na conexão com o banco de dados.
    #
    # Efeito colateral: Encaminha as credenciais aos serviços
    # correspondentes, que realizam consultas ao banco de dados.
    # Não cria nem modifica a sessão do usuário.
    def autenticar(matricula)
        parametros = { matricula: matricula, senha: params[:senha] }

        if matricula.start_with?("9999")
            AutenticacaoAdministradorService.call(**parametros)
        elsif matricula.start_with?("999")
            AutenticacaoFuncionarioService.call(**parametros, agora: Time.current)
        else
            AutenticacaoUsuarioService.call(**parametros)
        end
    end

    ##
    # Trata uma tentativa de autenticação malsucedida.
    #
    # Define uma mensagem de erro temporária e renderiza novamente
    # a página de login, informando que as credenciais ou as condições
    # de autenticação não foram aceitas.
    #
    # @return [ActionController::Metal::Rendering] Resultado
    #   da renderização da página de login com status HTTP 401.
    #
    # Efeito colateral: Define uma mensagem flash temporária
    # e renderiza a página de login com status :unauthorized.
    def falha_autenticacao
        flash.now[:alert] = "Não foi possível autenticar. Confira suas credenciais e o horário permitido."

        render "sessoes/new", status: :unauthorized
    end

    ##
    # Trata falhas de conexão com o banco de dados durante
    # o processo de autenticação.
    #
    # Registra o erro no log da aplicação, apresenta uma mensagem
    # de indisponibilidade e renderiza novamente a página de login
    # com status HTTP 503.
    #
    # @param exception [Exception] Exceção relacionada à falha
    #   de conexão com o banco de dados.
    #
    # @return [ActionController::Metal::Rendering] Resultado
    #   da renderização da página de login com status HTTP 503.
    #
    # Efeito colateral: Registra uma mensagem de erro no log,
    # define uma mensagem flash temporária e renderiza a página
    # de login com status :service_unavailable.
    def render_indisponibilidade(exception)
        Rails.logger.error(
            "Falha de conexão durante o login: #{exception.message}"
        )

        flash.now[:alert] = "O serviço está indisponivel no momento. Tente novamente mais tarde."

        render "sessoes/new", status: :service_unavailable
    end

    ##
    # Determina a página inicial de acordo com o perfil do usuário.
    #
    # Administradores são direcionados à área administrativa,
    # funcionários à configuração do ponto de acesso e os demais
    # usuários à página inicial dos estudantes.
    #
    # @param usuario [Usuario] Usuário autenticado cujo perfil
    #   será utilizado para determinar a página de destino.
    #
    # @return [String] Caminho da página inicial correspondente
    #   ao perfil do usuário.
    #
    # Efeito colateral: Não modifica o banco de dados nem a sessão.
    # Apenas determina e retorna o caminho utilizado no redirecionamento.
    def pagina_inicial(usuario)
        if usuario.administrador?
            admin_restaurantes_path
        elsif usuario.funcionario?
            operator_ponto_configuracao_path
        else
            student_inicio_path
        end
    end
end
