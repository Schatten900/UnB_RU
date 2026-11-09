require "rails_helper"

RSpec.describe "Autenticacao", type: :request do
  let(:turno) do
    Turno.create!(nome: "Expediente", inicio: "09:00", fim: "17:00", preco: 0)
  end

  def criar_usuario(matricula:, turno:)
    Usuario.create!(
      matricula: matricula,
      nome: "Pessoa de teste",
      senha: "senha-segura",
      perfil: "estudante",
      turno: turno,
      saldo: 10
    )
  end

  it "renderiza a tela de login" do
    get login_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("login-form")
  end

  it "autentica estudante e direciona ao inicio" do
    estudante = criar_usuario(matricula: "232040501", turno: turno)

    post login_path, params: { matricula: estudante.matricula, senha: "senha-segura" }

    expect(response).to redirect_to(root_path)
    expect(session[:usuario_matricula]).to eq(estudante.matricula)
  end

  it "autentica funcionario dentro do turno e direciona a configuracao" do
    funcionario = criar_usuario(matricula: "999123456", turno: turno)
    allow(Time).to receive(:current).and_return(Time.find_zone!("America/Sao_Paulo").local(2026, 10, 30, 12, 0))

    post login_path, params: { matricula: funcionario.matricula, senha: "senha-segura" }

    expect(response).to redirect_to(ponto_configuracao_path)
    expect(session[:usuario_matricula]).to eq(funcionario.matricula)
  end

  it "autentica administrador fora do horario do turno e permite acesso a configuracao" do
    administrador = criar_usuario(matricula: "999912345", turno: turno)

    post login_path, params: { matricula: administrador.matricula, senha: "senha-segura" }

    expect(response).to redirect_to(ponto_configuracao_path)
    expect(session[:usuario_matricula]).to eq(administrador.matricula)

    get ponto_configuracao_path

    expect(response).to have_http_status(:ok)
  end

  it "recusa credenciais incorretas sem criar sessao" do
    funcionario = criar_usuario(matricula: "999123456", turno: turno)

    post login_path, params: { matricula: funcionario.matricula, senha: "incorreta" }

    expect(response).to have_http_status(:unauthorized)
    expect(session[:usuario_matricula]).to be_nil
  end
end