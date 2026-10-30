require "test_helper"

class CardapioTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "cardápio exige data" do
    cardapio = Cardapio.new(data: nil)

    assert_not cardapio.valid?
    assert_includes cardapio.errors[:data], "can't be blank"
  end

  test "cardápio exige turno" do
    cardapio = Cardapio.new(
      data: Date.current,
      opcao_padrao: "Frango assado",
      opcao_ovolactovegetariana: "Omelete",
      opcao_vegetariana_estrita: "Suflê de chuchu"
    )

    assert_not cardapio.valid?
    assert_includes cardapio.errors[:turno], "must exist"
  end
end
