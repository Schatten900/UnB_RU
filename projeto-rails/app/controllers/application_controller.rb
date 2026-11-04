class ApplicationController < ActionController::Base
    helper_method :usuario_atual

    private

    def current_usuario
        usuario_atual
    end

    def authenticate_usuario!
        return if current_usuario

        render json: { erro: "Autenticação necessária" }, status: :unauthorized
    end

    def usuario_atual
        return unless session[:usuario_matricula]

        @usuario_atual ||= Usuario.find_by(matricula: session[:usuario_matricula])
    end

    def restaurante_atual
        return unless session[:restaurante_id]

        @restaurante_atual ||= Restaurante.find_by(id: session[:restaurante_id])
        session.delete(:restaurante_id) unless @restaurante_atual
        @restaurante_atual
    end

    def exigir_funcionario
        return if usuario_atual&.funcionario? || usuario_atual&.administrador?

        reset_session
        redirect_to login_path, alert: "Acesso não autorizado."

    end

end
