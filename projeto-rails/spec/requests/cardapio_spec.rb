require "rails_helper"

RSpec.describe "Cardapio", type: :request do
  let(:zona) { Time.find_zone!("America/Sao_Paulo") }
  let(:turno) do
    Turno.create!(nome: "Almoco", inicio: "11:00", fim: "14:00", preco: 4.50)
  end

  def autenticar_estudante
    usuario = Usuario.create!(
      matricula: "232040501",
      nome: "Pessoa de teste",
      senha: "senha-segura",
      perfil: "estudante",
      saldo: 18
    )
    post login_path, params: { matricula: usuario.matricula, senha: "senha-segura" }
  end

  it "redireciona visitantes da raiz para o login" do
    get root_path

    expect(response).to redirect_to(login_path)
  end

  it "mostra as opcoes do cardapio do turno vigente" do
    Cardapio.create!(
      turno: turno,
      data: Date.new(2026, 10, 30),
      opcao_padrao: "Arroz com legumes",
      opcao_ovolactovegetariana: "Omelete de forno",
      opcao_vegetariana_estrita: "Feijao com abobora"
    )
    allow(Time).to receive(:current).and_return(zona.local(2026, 10, 30, 12, 0))
    autenticar_estudante

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Arroz com legumes", "Omelete de forno", "Feijao com abobora", "Almoco")
  end

  it "exibe o painel inicial na raiz junto com o cardapio" do
    Cardapio.create!(
      turno: turno,
      data: Date.new(2026, 10, 30),
      opcao_padrao: "Arroz com legumes",
      opcao_ovolactovegetariana: "Omelete de forno",
      opcao_vegetariana_estrita: "Feijao com abobora"
    )
    allow(Time).to receive(:current).and_return(zona.local(2026, 10, 30, 12, 0))
    autenticar_estudante

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Início &amp; Carteira", "Olá, Pessoa de teste", "Saldo da carteira estudantil", "Cardápio de Almoco", "Arroz com legumes")
  end

  it "não disponibiliza mais a rota dedicada do cardapio" do
    get "/cardapio"

    expect(response).to have_http_status(:not_found)
  end

  it "mostra o saldo do usuario autenticado no painel inicial" do
    usuario = Usuario.create!(
      matricula: "232040501",
      nome: "Pessoa de teste",
      senha: "senha-segura",
      perfil: "estudante",
      saldo: 18
    )
    Cardapio.create!(
      turno: turno,
      data: Date.new(2026, 10, 30),
      opcao_padrao: "Arroz com legumes",
      opcao_ovolactovegetariana: "Omelete de forno",
      opcao_vegetariana_estrita: "Feijao com abobora"
    )
    allow(Time).to receive(:current).and_return(zona.local(2026, 10, 30, 12, 0))
    post login_path, params: { matricula: usuario.matricula, senha: "senha-segura" }

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Olá, Pessoa de teste", "R$ 18,00", "Seu saldo cobre até 4 refeições")
  end

  it "mostra estado vazio sem cardapio para o turno vigente" do
    allow(Time).to receive(:current).and_return(zona.local(2026, 10, 30, 12, 0))
    autenticar_estudante

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Não há cardápio disponível agora")
    expect(response.body).not_to include("meal-card")
  end
end