require "rails_helper"

RSpec.describe "Cardapio", type: :request do
  let(:zona) { Time.find_zone!("America/Sao_Paulo") }
  let(:turno) do
    Turno.create!(nome: "Almoco", inicio: "11:00", fim: "14:00", preco: 4.50)
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

    get cardapio_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Arroz com legumes", "Omelete de forno", "Feijao com abobora", "Almoco")
  end

  it "mostra estado vazio sem cardapio para o turno vigente" do
    allow(Time).to receive(:current).and_return(zona.local(2026, 10, 30, 12, 0))

    get cardapio_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Não há cardápio disponível agora")
    expect(response.body).not_to include("meal-card")
  end
end