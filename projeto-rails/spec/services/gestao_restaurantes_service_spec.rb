require "rails_helper"

RSpec.describe GestaoRestaurantesService do
  let(:administrador) { double("Administrador", perfil: "administrador") }
  let(:funcionario) { double("Funcionario", perfil: "funcionario") }

  it "cadastra um restaurante e uma catraca associada" do
    restaurante = described_class.cadastrar_restaurante(
      usuario: administrador, nome: "RU Darcy Ribeiro"
    )
    catraca = described_class.cadastrar_catraca(
      usuario: administrador, restaurante: restaurante, piso: 2
    )

    expect(restaurante).to be_persisted
    expect(catraca).to be_persisted
    expect(catraca.restaurante).to eq(restaurante)
    expect(described_class.listar_restaurantes).to include(restaurante)
  end

  it "edita um restaurante e sua catraca" do
    restaurante = Restaurante.create!(nome: "RU Gama")
    catraca = Catraca.create!(restaurante: restaurante, piso: 1, modo_acesso: "normal")

    described_class.editar_restaurante(
      usuario: administrador, restaurante: restaurante, nome: "RU FCTE"
    )
    described_class.editar_catraca(
      usuario: administrador, catraca: catraca, piso: 2
    )

    expect(restaurante.reload.nome).to eq("RU FCTE")
    expect(catraca.reload.piso).to eq(2)
  end

  it "remove a catraca e depois o restaurante" do
    restaurante = Restaurante.create!(nome: "RU Gama")
    catraca = Catraca.create!(restaurante: restaurante, piso: 1, modo_acesso: "normal")

    described_class.remover_catraca(usuario: administrador, catraca: catraca)
    described_class.remover_restaurante(usuario: administrador, restaurante: restaurante)

    expect(Catraca.exists?(catraca.id)).to be(false)
    expect(Restaurante.exists?(restaurante.id)).to be(false)
  end

  it "nega operacoes de escrita para funcionarios nao administradores" do
    expect do
      described_class.cadastrar_restaurante(usuario: funcionario, nome: "RU Indevido")
    end.to raise_error(GestaoRestaurantesService::AcessoNegado)

    expect(Restaurante.exists?(nome: "RU Indevido")).to be(false)
  end
end
