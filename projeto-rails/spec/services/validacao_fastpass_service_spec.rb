require "rails_helper"

RSpec.describe ValidacaoFastpassService, type: :service do
  let(:zona) { Time.find_zone!("America/Sao_Paulo") }
  let(:agora) { zona.local(2026, 10, 15, 12, 20) }
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

  def validar(usuario: estudante, inscricao_alvo: :padrao, janela_alvo: :padrao, instante: agora)
    inscricao_dada = inscricao_alvo == :padrao ? inscricao : inscricao_alvo
    janela_dada = janela_alvo == :padrao ? time_frame : janela_alvo
    described_class.call(
      usuario: usuario, catraca: catraca, turno: turno,
      inscricao: inscricao_dada, time_frame: janela_dada,
      liberador: liberador, agora: instante
    )
  end

  it "autoriza vencedor e cria Acesso pendente sem debitar" do
    expect { @resultado = validar }.to change(Acesso, :count).by(1)

    expect(@resultado.autorizado?).to be(true)
    expect(@resultado.motivo).to eq(:autorizado)
    expect(@resultado.acesso).to be_persisted
    expect(@resultado.acesso.status).to eq("pendente")
    expect(@resultado.acesso.passagem_em).to be_nil
    expect(@resultado.acesso.valor_debitado).to eq(0.to_d)
    expect(@resultado.acesso.inscricao_fastpass_id).to eq(inscricao.id)
    expect(@resultado.acesso.data_hora).to eq(agora)
    expect(estudante.reload.saldo).to eq(15.5.to_d)
    expect(liberador.comandos).to eq([catraca.id])
  end

  it "bloqueia fora do horario e registra tentativa sem debitar" do
    resultado = validar(instante: zona.local(2026, 10, 15, 12, 31))

    expect(resultado.autorizado?).to be(false)
    expect(resultado.motivo).to eq(:fora_da_janela)
    expect(resultado.acesso.status).to eq("bloqueado")
    expect(resultado.acesso.passagem_em).to be_nil
    expect(resultado.acesso.valor_debitado).to eq(0.to_d)
    expect(estudante.reload.saldo).to eq(15.5.to_d)
    expect(liberador.comandos).to be_empty
  end

  it "bloqueia vencedor que tenta usar uma catraca diferente da atribuída" do
    outra = restaurante.catracas.create!(piso: 2, modo_acesso: "fastpass")
    inscricao.update!(catraca: outra)
    resultado = validar
    expect(resultado.autorizado?).to be(false)
    expect(resultado.motivo).to eq(:catraca_incorreta)
    expect(liberador.comandos).to be_empty
    expect(estudante.reload.saldo).to eq(15.5.to_d)
  end

  it "bloqueia quando o saldo e insuficiente" do
    estudante.update!(saldo: "3.50")

    resultado = validar

    expect(resultado.motivo).to eq(:saldo_insuficiente)
    expect(resultado.acesso.status).to eq("bloqueado")
    expect(estudante.reload.saldo).to eq(3.5.to_d)
    expect(liberador.comandos).to be_empty
  end

  it "bloqueia estudante sem FastPass e ainda registra Acesso" do
    resultado = validar(inscricao_alvo: nil, janela_alvo: nil)

    expect(resultado.motivo).to eq(:sem_fastpass)
    expect(resultado.acesso.status).to eq("bloqueado")
    expect(resultado.acesso.inscricao_fastpass_id).to be_nil
    expect(Acesso.count).to eq(1)
    expect(liberador.comandos).to be_empty
  end

  it "rejeita inscricao nao vencedora" do
    allow(inscricao).to receive(:resultado).and_return(InscricaoFastpass::RESULTADO_NAO_GANHOU)

    expect(validar.motivo).to eq(:sem_fastpass)
    expect(Acesso.last.status).to eq("bloqueado")
  end

  it "rejeita uma inscricao de outro estudante" do
    allow(inscricao).to receive(:usuario_matricula).and_return("999999999")

    expect(validar.motivo).to eq(:sem_fastpass)
    expect(Acesso.last.status).to eq("bloqueado")
  end

  it "rejeita uma janela diferente daquela vinculada a inscricao" do
    allow(inscricao).to receive(:time_frame_id).and_return(-1)

    expect(validar.motivo).to eq(:sem_fastpass)
    expect(Acesso.last.status).to eq("bloqueado")
  end

  it "nao aceita o resultado legado contemplada" do
    allow(inscricao).to receive(:resultado).and_return("contemplada")

    expect(validar.motivo).to eq(:sem_fastpass)
    expect(Acesso.last.status).to eq("bloqueado")
  end

  it "inclui inicio e exclui fim da janela" do
    entrada = validar(instante: zona.local(2026, 10, 15, 12, 15))
    saida = validar(instante: zona.local(2026, 10, 15, 12, 30))

    expect(entrada.acesso.status).to eq("pendente")
    expect(saida.acesso.status).to eq("bloqueado")
    expect(Acesso.count).to eq(2)
  end

  it "delega o modo normal sem criar um Acesso" do
    catraca.update!(modo_acesso: "normal")

    expect { @resultado = validar }.not_to change(Acesso, :count)
    expect(@resultado.motivo).to eq(:modo_nao_fastpass)
    expect(@resultado.acesso).to be_nil
    expect(liberador.comandos).to be_empty
  end

  it "registra bloqueio se o mock da catraca nao liberar" do
    allow(liberador).to receive(:liberar).and_return(false)

    resultado = validar

    expect(resultado.motivo).to eq(:falha_liberacao)
    expect(resultado.acesso.status).to eq("bloqueado")
    expect(estudante.reload.saldo).to eq(15.5.to_d)
  end

  it "nao registra tentativa de usuario nao identificado (FK obrigatoria)" do
    expect { @resultado = validar(usuario: nil) }.not_to change(Acesso, :count)
    expect(@resultado.motivo).to eq(:usuario_invalido)
    expect(liberador.comandos).to be_empty
  end
end
