class NotificacoesController < ApplicationController
  before_action :exigir_estudante

  def index
    @notificacoes = Notificacao.where(usuario_matricula: usuario_atual.matricula)
                               .order(created_at: :desc)
  end

  private

  def exigir_estudante
    return if usuario_atual&.estudante?

    redirect_to login_path, alert: "Acesso restrito a estudantes autenticados."
  end
end