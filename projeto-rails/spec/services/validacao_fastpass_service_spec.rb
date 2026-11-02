require "rails_helper"

RSpec.describe ValidacaoFastpassService, type: :service do
  let(:zona) { Time.find_zone!("America/Sao_Paulo") }
  let(:agora) { zona.local(2026, 10, 15, 12, 20) }
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
           time_frame_id: time_frame.id, resultado: "ganhou")
  end
  let(:repositorio) { RegistroValidacoesRepositoryMock.new }
  let(:liberador) { LiberadorCatracaMock.new }

  def validar(saldo: nil, instante: nil, inscricao_alvo: :padrao,
              time_frame_alvo: :padrao)
    aluno = estudante
    aluno.update!(saldo: saldo) unless saldo.nil?
    inscricao_dada = inscricao_alvo == :padrao ? inscricao : inscricao_alvo
    janela_dada = time_frame_alvo == :padrao ? time_frame : time_frame_alvo

    described_class.call(
      usuario: aluno, catraca: catraca, inscricao: inscricao_dada,
      time_frame: janela_dada, preco: BigDecimal("4.50"),
      repositorio: repositorio, liberador: liberador, agora: instante || agora
    )
  end

  it "autoriza vencedor no horario e nao debita antes da passagem" do
    expect { @resultado = validar }.not_to change { Acesso.count }

    expect(@resultado.autorizado?).to be(true)
    expect(estudante.reload.saldo).to eq(BigDecimal("15.50"))
    expect(liberador.comandos).to eq([4])
    expect(repositorio.listar(catraca_id: 4)).to be_empty
  end

  it "bloqueia acesso fora da janela sem cobrar ou liberar a catraca" do
    resultado = validar(instante: zona.local(2026, 10, 15, 12, 31))

    expect(resultado.autorizado?).to be(false)
    expect(resultado.motivo).to eq(:fora_da_janela)
    expect(estudante.reload.saldo).to eq(BigDecimal("15.50"))
    expect(liberador.comandos).to be_empty
    expect(repositorio.listar(catraca_id: 4).map(&:status)).to eq(["Bloqueado"])
  end

  it "bloqueia acesso por saldo insuficiente" do
    resultado = validar(saldo: BigDecimal("3.50"))

    expect(resultado.motivo).to eq(:saldo_insuficiente)
    expect(estudante.reload.saldo).to eq(BigDecimal("3.50"))
    expect(liberador.comandos).to be_empty
    expect(repositorio.listar(catraca_id: 4).first.status).to eq("Bloqueado")
  end

  it "bloqueia estudante sem FastPass" do
    resultado = validar(inscricao_alvo: nil, time_frame_alvo: nil)

    expect(resultado.motivo).to eq(:sem_fastpass)
    expect(liberador.comandos).to be_empty
    expect(repositorio.listar(catraca_id: 4).first.status).to eq("Bloqueado")
  end

  it "nao aceita inscricao nao vencedora ou de outra pessoa" do
    allow(inscricao).to receive(:resultado).and_return("nao contemplada")
    expect(validar.motivo).to eq(:sem_fastpass)

    allow(inscricao).to receive(:resultado).and_return("ganhou")
    allow(inscricao).to receive(:usuario_matricula).and_return("999999999")
    expect(validar.motivo).to eq(:sem_fastpass)
    expect(liberador.comandos).to be_empty
  end

  it "nao aceita janela diferente daquela vinculada a inscricao" do
    allow(inscricao).to receive(:time_frame_id).and_return(8)

    expect(validar.motivo).to eq(:sem_fastpass)
    expect(liberador.comandos).to be_empty
  end

  it "tambem aceita a nomenclatura contemplada usada no codigo de Carlos" do
    allow(inscricao).to receive(:resultado).and_return("contemplada")

    expect(validar.autorizado?).to be(true)
  end

  it "inclui o inicio e exclui o fim do intervalo" do
    expect(validar(instante: zona.local(2026, 10, 15, 12, 15)).autorizado?).to be(true)
    expect(validar(instante: zona.local(2026, 10, 15, 12, 30)).motivo).to eq(:fora_da_janela)
  end

  it "delega o modo normal a validacao geral sem registrar bloqueio" do
    allow(catraca).to receive(:modo_acesso).and_return("normal")

    expect(validar.motivo).to eq(:modo_nao_fastpass)
    expect(liberador.comandos).to be_empty
    expect(repositorio.listar(catraca_id: 4)).to be_empty
  end

  it "registra bloqueio quando o simulador da catraca nao libera" do
    allow(liberador).to receive(:liberar).and_return(false)

    expect(validar.motivo).to eq(:falha_liberacao)
    expect(repositorio.listar(catraca_id: 4).first.status).to eq("Bloqueado")
    expect(estudante.reload.saldo).to eq(BigDecimal("15.50"))
  end
end
