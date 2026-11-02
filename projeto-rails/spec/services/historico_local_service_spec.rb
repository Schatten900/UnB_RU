require "rails_helper"

RSpec.describe HistoricoLocalService, type: :service do
  let(:funcionario) { double("Funcionario", funcionario?: true) }
  let(:estudante) { double("Estudante", funcionario?: false) }
  let(:repositorio) { RegistroValidacoesRepositoryMock.new }
  let(:instante) { Time.zone.parse("2026-10-15 12:00") }

  before do
    repositorio.registrar(catraca_id: 4, usuario_matricula: "221012345",
                          status: "Liberado", data_hora: instante)
    repositorio.registrar(catraca_id: 4, usuario_matricula: "231045229",
                          status: "Bloqueado", data_hora: instante + 1.minute)
    repositorio.registrar(catraca_id: 2, usuario_matricula: "251123339",
                          status: "Liberado", data_hora: instante + 2.minutes)
  end

  def consultar(catraca_id:, usuario: funcionario)
    described_class.call(usuario: usuario, catraca_id: catraca_id,
                         repositorio: repositorio)
  end

  it "mostra tentativas liberadas e bloqueadas da catraca selecionada" do
    historico = consultar(catraca_id: 4)

    expect(historico.map(&:usuario_matricula)).to eq(%w[231045229 221012345])
    expect(historico.map(&:status)).to eq(%w[Bloqueado Liberado])
  end

  it "nao mostra validacoes registradas em outras catracas" do
    historico = consultar(catraca_id: 2)

    expect(historico.map(&:usuario_matricula)).to eq(["251123339"])
  end

  it "nega acesso a quem nao e funcionario" do
    expect do
      consultar(catraca_id: 4, usuario: estudante)
    end.to raise_error(HistoricoLocalService::AcessoNegado)
  end

  it "retorna vazio quando nenhuma catraca foi selecionada" do
    expect(consultar(catraca_id: nil)).to be_empty
  end

  it "retorna registros em ordem decrescente de horario" do
    historico = consultar(catraca_id: 4)

    expect(historico.map(&:data_hora)).to eq([instante + 1.minute, instante])
  end
end
