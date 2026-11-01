require "test_helper"

class CardapioControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []
  BRASILIA = Time.find_zone!("America/Sao_Paulo")

  setup do
    @turno = Turno.create!(nome: "Almoço", inicio: "11:00", fim: "14:00", preco: 4.50)
  end

  test "mostra as opções do cardápio do turno atual" do
    Cardapio.create!(
      turno: @turno,
      data: Date.new(2026, 10, 30),
      opcao_padrao: "Arroz com legumes",
      opcao_ovolactovegetariana: "Omelete de forno",
      opcao_vegetariana_estrita: "Feijão com abóbora"
    )

    travel_to BRASILIA.local(2026, 10, 30, 12, 0) do
      get cardapio_path
    end

    assert_response :success
    assert_select "main.menu-app"
    assert_select ".meal-card", 3
    assert_select ".meal-card", text: /Arroz com legumes/
    assert_select ".meal-card", text: /Omelete de forno/
    assert_select ".meal-card", text: /Feijão com abóbora/
    assert_select ".meal-meta", text: /Almoço/
  end

  test "mostra estado vazio quando não há cardápio para o turno vigente" do
    travel_to BRASILIA.local(2026, 10, 30, 12, 0) do
      get cardapio_path
    end

    assert_response :success
    assert_select ".menu-empty", text: /Não há cardápio disponível agora/
    assert_select ".meal-card", count: 0
  end
end