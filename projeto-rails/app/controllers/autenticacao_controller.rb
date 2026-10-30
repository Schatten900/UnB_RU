class AutenticacaoController < ApplicationController

    def new
        render "sessoes/new"
    end

    def create
        matricula = params[:matricula].to_s.strip

        if matricula.start_with?("999")
            usuario = AutenticacaoFuncionarioService.call(
                matricula: matricula,
                senha: params[:senha],
                agora: Time.current
            )
        else
            usuario = AutenticacaoUsuarioService.call(
                matricula: matricula,
                senha: params[:senha]
            )
        end

        if usuario
            reset_session               # Cria uma nova sessão
            session[:usuario_matricula] = usuario.matricula # Registra na sessão a matricula logada

            redirect_to ponto_configuracao_path, notice: "Login realizado com sucesso."
        else
            flash.now[:alert] = "Não foi possível autenticar. Confira suas credenciais e o horário permitido."

            render "sessoes/new", status: :unauthorized

        end

    rescue ActiveRecord::ConnectionNotEstablished,
        ActiveRecord::ConnectionTimeoutError => e

        Rails.logger.error("Falha de conexão durante o login: #{e.message}")

        flash.now[:alert] = "O serviço está indisponivel no momento. Tente novamente mais tarde."

        render "sessoes/new", status: :service_unavailable

    end

    def destroy
        reset_session
        redirect_to login_path, notice:  "Sessão encerrada."

    end
end