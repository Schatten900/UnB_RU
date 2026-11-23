module Admin
  class BaseController < ApplicationController
    before_action :exigir_administrador

    private

    def exigir_administrador
      return if usuario_atual&.administrador?

      redirect_to login_path, alert: "Acesso restrito a administradores."
    end
  end
end
