require "rails_helper"

RSpec.describe CardapioServices, type: :service do
  it "localiza cardapio de turno que atravessa a meia-noite" do
    turno = Turno.create!(nome: "Noturno", inicio: "22:00", fim: "02:00", preco: 4.50)
    cardapio = Cardapio.create!(
      turno: turno,
      data: Date.new(2026, 10, 30),
      opcao_padrao: "Sopa",
      opcao_ovolactovegetariana: "Omelete",
      opcao_vegetariana_estrita: "Legumes"
    )

    resultado = described_class.call(
      now: Time.find_zone!("America/Sao_Paulo").local(2026, 10, 30, 23, 0)
    )

    expect(resultado).to eq(cardapio)
  end
end