require "test_helper"

class CardapioServicesTest < ActiveSupport::TestCase
  self.fixture_table_names = []
  BRASILIA = Time.find_zone!("America/Sao_Paulo")

  test "retorna o cardápio do turno ativo e da data atual" do
    turno = criar_turno(inicio: "12:00", fim: "13:00")
    cardapio = criar_cardapio(turno)

    resultado = CardapioServices.call(now: BRASILIA.local(2026, 10, 30, 12, 30))

    assert_equal cardapio, resultado
  end

  test "não inclui o instante final do turno" do
    criar_turno(inicio: "12:00", fim: "13:00")

    resultado = CardapioServices.call(now: BRASILIA.local(2026, 10, 30, 13, 0))

    assert_nil resultado
  end

  test "interpreta corretamente o horário do turno no fuso local" do
    turno = criar_turno(inicio: "17:00", fim: "20:00")
    cardapio = criar_cardapio(turno)

    resultado = CardapioServices.call(now: BRASILIA.local(2026, 10, 30, 19, 41))

    assert_equal cardapio, resultado
  end

  test "retorna nil quando não há cardápio para o turno ativo" do
    criar_turno(inicio: "12:00", fim: "13:00")

    resultado = CardapioServices.call(now: BRASILIA.local(2026, 10, 30, 12, 30))

    assert_nil resultado
  end

  private

  def criar_turno(inicio:, fim:)
    Turno.create!(nome: "Almoço", inicio: inicio, fim: fim, preco: 4.5)
  end

  def criar_cardapio(turno)
    Cardapio.create!(
      turno: turno,
      data: Date.new(2026, 10, 30),
      opcao_padrao: "Frango",
      opcao_ovolactovegetariana: "Omelete",
      opcao_vegetariana_estrita: "Quinoa"
    )
  end
end