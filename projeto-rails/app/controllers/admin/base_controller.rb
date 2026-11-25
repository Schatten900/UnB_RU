module Admin
  class BaseController < ApplicationController
    before_action :exigir_administrador

    private

    # Restringe os controllers derivados a administradores autenticados.
    # Sem argumentos; retorna nil ou redirecionamento, sem alterar o banco.
    def exigir_administrador
      return if usuario_atual&.administrador?

      redirect_to login_path, alert: "Acesso restrito a administradores."
    end
  end
end
