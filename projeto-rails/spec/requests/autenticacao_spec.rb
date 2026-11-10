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

  it "renderiza o login na raiz sem autenticação" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("login-form")
  end

  it "autentica estudante e direciona ao inicio" do
    estudante = criar_usuario(matricula: "232040501", turno: turno)

    post login_path, params: { matricula: estudante.matricula, senha: "senha-segura" }

    expect(response).to redirect_to(student_inicio_path)
    expect(session[:usuario_matricula]).to eq(estudante.matricula)

    get root_path
    expect(response).to redirect_to(student_inicio_path)
  end

  it "autentica funcionario dentro do turno e direciona a configuracao" do
    funcionario = criar_usuario(matricula: "999123456", turno: turno)
    allow(Time).to receive(:current).and_return(Time.find_zone!("America/Sao_Paulo").local(2026, 10, 30, 12, 0))

    post login_path, params: { matricula: funcionario.matricula, senha: "senha-segura" }

    expect(response).to redirect_to(operator_ponto_configuracao_path)
    expect(session[:usuario_matricula]).to eq(funcionario.matricula)

    get root_path
    expect(response).to redirect_to(operator_ponto_configuracao_path)
  end

  it "autentica administrador e direciona à gestão de restaurantes, mantendo acesso à configuração" do
    administrador = criar_usuario(matricula: "999912345", turno: turno)

    post login_path, params: { matricula: administrador.matricula, senha: "senha-segura" }

    expect(response).to redirect_to(admin_restaurantes_path)
    expect(session[:usuario_matricula]).to eq(administrador.matricula)

    get root_path
    expect(response).to redirect_to(admin_restaurantes_path)

    get operator_ponto_configuracao_path

    expect(response).to have_http_status(:ok)
  end

  it "recusa credenciais incorretas sem criar sessao" do
    funcionario = criar_usuario(matricula: "999123456", turno: turno)

    post login_path, params: { matricula: funcionario.matricula, senha: "incorreta" }

    expect(response).to have_http_status(:unauthorized)
    expect(session[:usuario_matricula]).to be_nil
  end
end
