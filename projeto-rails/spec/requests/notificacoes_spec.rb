require "rails_helper"

RSpec.describe "Notificacoes do estudante", type: :request do
  it "exibe somente notificacoes vinculadas ao estudante autenticado" do
    estudante = Usuario.create!(
      matricula: "221012345",
      nome: "Estudante",
      senha: "senha-segura",
      perfil: "estudante",
      saldo: 0
    )
    outro_estudante = Usuario.create!(
      matricula: "221012346",
      nome: "Outro estudante",
      senha: "senha-segura",
      perfil: "estudante",
      saldo: 0
    )
    Notificacao.create!(usuario: estudante, mensagem: "Você ganhou o FastPass.")
    Notificacao.create!(usuario: outro_estudante, mensagem: "Notificação privada de outra pessoa.")

    post login_path, params: { matricula: estudante.matricula, senha: "senha-segura" }
    get student_notificacoes_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Você ganhou o FastPass.")
    expect(response.body).not_to include("Notificação privada de outra pessoa.")
  end

  it "exige uma sessão de estudante" do
    get student_notificacoes_path

    expect(response).to redirect_to(login_path)
  end
end