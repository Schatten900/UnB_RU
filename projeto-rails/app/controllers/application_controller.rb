class ApplicationController < ActionController::Base
  helper_method :current_usuario, :usuario_atual

  private

  def current_usuario
    # Se houver sessão, busca o usuário logado. Senão, pega o primeiro do banco para não quebrar a tela de testes!
    if session[:usuario_matricula].present?
      @current_usuario ||= Usuario.find_by(matricula: session[:usuario_matricula])
    else
      # Usuário de testes temporário (pega o primeiro ou cria um fictício)
      @current_usuario ||= Usuario.first || Usuario.new(nome: "Estudante Teste", saldo: 50.0)
    end
  end
  alias_method :usuario_atual, :current_usuario
end

# AI: Gemini
# Strategy and prompt: This file was modified by multiple prompts while handling other functions