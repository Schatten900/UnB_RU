require "rails_helper"

RSpec.describe "Historico de refeicoes consumidas", type: :model do
  let(:usuario) do
    Usuario.create!(matricula: "221012345", nome: "Aluno", senha_hash: "hash", saldo: 20)
  end
  let(:restaurante) { Restaurante.create!(nome: "RU Darcy Ribeiro") }
  let(:catraca) { Catraca.create!(restaurante: restaurante, piso: 1, modo_acesso: "normal") }
  let(:turno) { Turno.create!(nome: "Almoco", inicio: "11:00", fim: "14:00", preco: "4.50") }

  it "nao confunde tentativas com refeicoes efetivamente consumidas" do
    bloqueado = Acesso.create!(usuario: usuario, catraca: catraca, turno: turno,
                               data_hora: Time.zone.parse("2026-10-15 12:00"),
                               status: "bloqueado", passagem_em: nil, valor_debitado: 0)
    confirmado = Acesso.create!(usuario: usuario, catraca: catraca, turno: turno,
                                data_hora: Time.zone.parse("2026-10-15 12:05"),
                                status: "liberado", passagem_em: Time.zone.parse("2026-10-15 12:06"),
                                valor_debitado: "4.50")

    expect(usuario.historico_refeicoes.map(&:id)).to eq([confirmado.id])
    expect(Acesso.where(usuario_matricula: usuario.matricula).pluck(:id)).to contain_exactly(bloqueado.id, confirmado.id)
  end
end
