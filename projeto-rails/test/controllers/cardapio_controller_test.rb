require "test_helper"

class CardapioControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []
  BRASILIA = Time.find_zone!("America/Sao_Paulo")

  setup do
    @turno = Turno.create!(nome: "Almoço", inicio: "11:00", fim: "14:00", preco: 4.50)
  end

  def autenticar_estudante
    estudante = Usuario.create!(
      matricula: "232040501",
      nome: "Estudante de teste",
      senha: "senha-segura",
      perfil: "estudante",
      saldo: 18
    )
    post login_path, params: { matricula: estudante.matricula, senha: "senha-segura" }
  end

  test "mostra as opções do cardápio do turno atual" do
    Cardapio.create!(
      turno: @turno,
      data: Date.new(2026, 10, 30),
      opcao_padrao: "Arroz com legumes",
      opcao_ovolactovegetariana: "Omelete de forno",
      opcao_vegetariana_estrita: "Feijão com abóbora"
    )

    autenticar_estudante
    travel_to BRASILIA.local(2026, 10, 30, 12, 0) do
      get inicio_path
    end

    assert_response :success
    assert_select "main.home-app"
    assert_select ".today-meal", 3
    assert_select ".today-meal", text: /Arroz com legumes/
    assert_select ".today-meal", text: /Omelete de forno/
    assert_select ".today-meal", text: /Feijão com abóbora/
    assert_select ".today-menu-title-row", text: /Almoço/
  end

  test "mostra estado vazio quando não há cardápio para o turno vigente" do
    autenticar_estudante
    travel_to BRASILIA.local(2026, 10, 30, 12, 0) do
      get inicio_path
    end

    assert_response :success
    assert_select ".today-menu-empty", text: /Não há cardápio disponível agora/
    assert_select ".today-meal", count: 0
  end
end
