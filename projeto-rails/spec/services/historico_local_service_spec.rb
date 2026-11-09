require "rails_helper"

RSpec.describe HistoricoLocalService, type: :service do
  let(:funcionario) do
    Usuario.create!(matricula: "999000001", nome: "Funcionario", senha_hash: "hash", saldo: 0)
  end
  let(:estudante) do
    Usuario.create!(matricula: "221012345", nome: "Estudante", senha_hash: "hash", saldo: 0)
  end
  let(:outro_estudante) do
    Usuario.create!(matricula: "231045229", nome: "Outro aluno", senha_hash: "hash", saldo: 0)
  end
  let(:terceiro_estudante) do
    Usuario.create!(matricula: "251123339", nome: "Terceiro aluno", senha_hash: "hash", saldo: 0)
  end
  let(:restaurante) { Restaurante.create!(nome: "RU Darcy Ribeiro") }
  let(:catraca_4) { Catraca.create!(restaurante: restaurante, piso: 4, modo_acesso: "normal") }
  let(:catraca_2) { Catraca.create!(restaurante: restaurante, piso: 2, modo_acesso: "normal") }
  let(:turno) { Turno.create!(nome: "Almoco", inicio: "11:00", fim: "14:00", preco: "4.50") }
  let(:instante) { Time.zone.parse("2026-10-15 12:00") }

  before do
    Acesso.create!(usuario: estudante, turno: turno, catraca: catraca_4,
                  status: "liberado", data_hora: instante,
                  passagem_em: instante, valor_debitado: "4.50")
    Acesso.create!(usuario: outro_estudante, turno: turno, catraca: catraca_4,
                  status: "bloqueado", data_hora: instante + 1.minute,
                  passagem_em: nil, valor_debitado: 0)
    Acesso.create!(usuario: terceiro_estudante, turno: turno, catraca: catraca_2,
                  status: "pendente", data_hora: instante + 2.minutes,
                  passagem_em: nil, valor_debitado: 0)
  end

  def consultar(catraca_id: catraca_4.id, usuario: funcionario)
    described_class.call(usuario: usuario, catraca_id: catraca_id)
  end

  it "exibe tentativas liberadas e bloqueadas da catraca selecionada" do
    historico = consultar

    expect(historico.map(&:usuario_matricula)).to eq(%w[231045229 221012345])
    expect(historico.map(&:status)).to eq(%w[bloqueado liberado])
  end

  it "nao exibe tentativas de outras catracas" do
    expect(consultar(catraca_id: catraca_2.id).map(&:usuario_matricula)).to eq(["251123339"])
  end

  it "impede consulta por estudante" do
    expect { consultar(usuario: estudante) }
      .to raise_error(HistoricoLocalService::AcessoNegado)
  end

  it "retorna vazio sem catraca selecionada" do
    expect(consultar(catraca_id: nil)).to be_empty
  end

  it "ordena pela data da tentativa decrescente" do
    expect(consultar.map(&:data_hora)).to eq([instante + 1.minute, instante])
  end
end
