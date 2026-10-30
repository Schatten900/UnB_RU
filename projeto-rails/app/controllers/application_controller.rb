class ApplicationController < ActionController::Base

    private

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
        return if usuario_atual&.funcionario?

        reset_session
        redirect_to login_path, alert: "Acesso não autorizado."

    end

end
