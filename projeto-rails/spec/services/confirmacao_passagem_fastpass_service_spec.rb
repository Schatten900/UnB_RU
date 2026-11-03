require "rails_helper"

RSpec.describe ConfirmacaoPassagemFastpassService, type: :service do
  let(:zona) { Time.find_zone!("America/Sao_Paulo") }
  let(:agora) { zona.local(2026, 10, 15, 12, 20) }
  let(:passagem_em) { zona.local(2026, 10, 15, 12, 21) }
  let(:estudante) do
    Usuario.create!(
      matricula: "221021212", nome: "Estudante", senha_hash: "hash",
      perfil: "estudante", saldo: BigDecimal("15.50")
    )
  end
  let(:catraca) { double("Catraca", id: 4, modo_acesso: "fastpass") }
  let(:time_frame) do
    double("TimeFrame", id: 7, turno_id: 1,
           inicio: Time.utc(2000, 1, 1, 12, 15),
           fim: Time.utc(2000, 1, 1, 12, 30))
  end
  let(:inscricao) do
    double("InscricaoFastpass", id: 3, usuario_matricula: estudante.matricula,
           time_frame_id: 7, resultado: "ganhou")
  end
  let(:repositorio) { RegistroValidacoesRepositoryMock.new }
  let(:liberador) { LiberadorCatracaMock.new }
  let(:resultado) do
    ValidacaoFastpassService.call(
      usuario: estudante, catraca: catraca, inscricao: inscricao,
      time_frame: time_frame, preco: BigDecimal("4.50"),
      repositorio: repositorio, liberador: liberador, agora: agora
    )
  end
  let(:acesso_mock) { double("Acesso criado") }

  before { allow(Acesso).to receive(:create!).and_return(acesso_mock) }

  it "debita somente apos confirmacao, solicita Acesso e registra Liberado" do
    expect { described_class.call(resultado: resultado, agora: passagem_em) }
      .to change { estudante.reload.saldo }
      .from(BigDecimal("15.50")).to(BigDecimal("11.00"))

    expect(Acesso).to have_received(:create!).with(
      usuario_matricula: "221021212", catraca_id: 4, turno_id: 1,
      inscricao_fastpass_id: 3, data_hora: agora, passagem_em: passagem_em,
      status: "liberado", valor_debitado: BigDecimal("4.50")
    ).once
    expect(resultado.confirmado?).to be(true)
    expect(repositorio.listar(catraca_id: 4).map(&:status)).to eq(["Liberado"])
  end

  it "nao cobra nem registra passagem quando a autorizacao foi bloqueada" do
    resultado_bloqueado = ValidacaoFastpassService.call(
      usuario: estudante, catraca: catraca, inscricao: nil,
      time_frame: nil, preco: BigDecimal("4.50"),
      repositorio: repositorio, liberador: liberador, agora: agora
    )

    expect do
      described_class.call(resultado: resultado_bloqueado, agora: passagem_em)
    end.to raise_error(ConfirmacaoPassagemFastpassService::PassagemNaoAutorizada)
    expect(Acesso).not_to have_received(:create!)
    expect(estudante.reload.saldo).to eq(BigDecimal("15.50"))
    expect(repositorio.listar(catraca_id: 4).map(&:status)).to eq(["Bloqueado"])
  end

  it "impede duas confirmacoes da mesma autorizacao" do
    described_class.call(resultado: resultado, agora: passagem_em)

    expect do
      described_class.call(resultado: resultado, agora: passagem_em)
    end.to raise_error(ConfirmacaoPassagemFastpassService::PassagemJaConfirmada)
    expect(estudante.reload.saldo).to eq(BigDecimal("11.00"))
    expect(Acesso).to have_received(:create!).once
    expect(repositorio.listar(catraca_id: 4).map(&:status)).to eq(["Liberado"])
  end

  it "reavalia o saldo no instante da confirmacao" do
    autorizacao = resultado
    estudante.update!(saldo: BigDecimal("0.00"))

    expect do
      described_class.call(resultado: autorizacao, agora: passagem_em)
    end.to raise_error(ConfirmacaoPassagemFastpassService::SaldoInsuficiente)
    expect(Acesso).not_to have_received(:create!)
    expect(estudante.reload.saldo).to eq(BigDecimal("0.00"))
    expect(repositorio.listar(catraca_id: 4)).to be_empty
  end

  it "nao debita caso a persistencia do Acesso falhe" do
    autorizacao = resultado
    allow(Acesso).to receive(:create!).and_raise("Falha simulada")

    expect do
      described_class.call(resultado: autorizacao, agora: passagem_em)
    end.to raise_error("Falha simulada")
    expect(estudante.reload.saldo).to eq(BigDecimal("15.50"))
    expect(autorizacao.confirmado?).to be(false)
    expect(repositorio.listar(catraca_id: 4)).to be_empty
  end
end
