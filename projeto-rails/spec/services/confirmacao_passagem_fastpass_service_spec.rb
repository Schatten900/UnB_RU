require "rails_helper"

RSpec.describe ConfirmacaoPassagemFastpassService, type: :service do
  let(:zona) { Time.find_zone!("America/Sao_Paulo") }
  let(:agora) { zona.local(2026, 10, 15, 12, 20) }
  let(:passagem_em) { zona.local(2026, 10, 15, 12, 21) }
  let(:estudante) do
    Usuario.create!(matricula: "221021212", nome: "Estudante", senha_hash: "hash", saldo: "15.50")
  end
  let(:restaurante) { Restaurante.create!(nome: "RU Darcy Ribeiro") }
  let(:catraca) { Catraca.create!(restaurante: restaurante, piso: 1, modo_acesso: "fastpass") }
  let(:turno) { Turno.create!(nome: "Almoco", inicio: "11:00", fim: "14:00", preco: "4.50") }
  let(:time_frame) { TimeFrame.create!(turno: turno, inicio: "12:15", fim: "12:30") }
  let(:sorteio) { Sorteio.create!(data: Date.new(2026, 10, 15), status: "aberto") }
  let(:inscricao) do
    InscricaoFastpass.create!(
      usuario: estudante, sorteio: sorteio, time_frame: time_frame,
      resultado: InscricaoFastpass::RESULTADO_GANHOU
    )
  end
  let(:liberador) { LiberadorCatracaMock.new }
  let(:resultado) do
    ValidacaoFastpassService.call(
      usuario: estudante, catraca: catraca, turno: turno,
      inscricao: inscricao, time_frame: time_frame,
      liberador: liberador, agora: agora
    )
  end

  it "atualiza o Acesso existente e debita somente apos confirmar" do
    tentativa = resultado.acesso
    expect(tentativa.status).to eq("pendente")
    expect(estudante.reload.saldo).to eq(15.5.to_d)

    expect do
      @acesso = described_class.call(resultado: resultado, agora: passagem_em)
    end.to change { estudante.reload.saldo }.from(15.5.to_d).to(11.to_d)

    expect(Acesso.count).to eq(1)
    expect(@acesso.id).to eq(tentativa.id)
    expect(@acesso.status).to eq("liberado")
    expect(@acesso.passagem_em).to eq(passagem_em)
    expect(@acesso.valor_debitado).to eq(4.5.to_d)
    expect(resultado.confirmado?).to be(true)
  end

  it "nao confirma uma tentativa bloqueada" do
    bloqueado = ValidacaoFastpassService.call(
      usuario: estudante, catraca: catraca, turno: turno,
      inscricao: nil, time_frame: nil,
      liberador: liberador, agora: agora
    )

    expect do
      described_class.call(resultado: bloqueado, agora: passagem_em)
    end.to raise_error(ConfirmacaoPassagemFastpassService::PassagemNaoAutorizada)

    expect(bloqueado.acesso.reload.status).to eq("bloqueado")
    expect(bloqueado.acesso.passagem_em).to be_nil
    expect(estudante.reload.saldo).to eq(15.5.to_d)
  end

  it "mantem a verificacao simples de confirmacao duplicada" do
    autorizacao = resultado
    described_class.call(resultado: autorizacao, agora: passagem_em)

    expect do
      described_class.call(resultado: autorizacao, agora: passagem_em)
    end.to raise_error(ConfirmacaoPassagemFastpassService::PassagemJaConfirmada)
    expect(estudante.reload.saldo).to eq(11.to_d)
    expect(Acesso.count).to eq(1)
  end

  it "nao debita se o saldo ficar insuficiente antes da confirmacao" do
    autorizacao = resultado
    estudante.update!(saldo: "0.00")

    expect do
      described_class.call(resultado: autorizacao, agora: passagem_em)
    end.to raise_error(ConfirmacaoPassagemFastpassService::SaldoInsuficiente)

    expect(autorizacao.acesso.reload.status).to eq("pendente")
    expect(autorizacao.acesso.passagem_em).to be_nil
    expect(autorizacao.confirmado?).to be(false)
    expect(estudante.reload.saldo).to eq(0.to_d)
  end

  it "desfaz o debito se a atualizacao do Acesso falhar" do
    autorizacao = resultado
    allow(autorizacao.acesso).to receive(:update!).and_raise("Falha simulada")

    expect do
      described_class.call(resultado: autorizacao, agora: passagem_em)
    end.to raise_error("Falha simulada")

    expect(estudante.reload.saldo).to eq(15.5.to_d)
    expect(autorizacao.acesso.reload.status).to eq("pendente")
    expect(autorizacao.confirmado?).to be(false)
  end
end
