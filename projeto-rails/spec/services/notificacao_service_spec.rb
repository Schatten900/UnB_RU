require "rails_helper"

RSpec.describe NotificacaoService, type: :service do
  let(:usuario) do
    Usuario.create!(
      matricula: "221012345",
      nome: "Estudante",
      senha_hash: "hash",
      perfil: "estudante",
      saldo: 0
    )
  end

  let(:inscricao) do
    sorteio = Sorteio.create!(data: Date.new(2026, 10, 30), status: "concluido")
    turno = Turno.create!(nome: "Almoco", inicio: "11:00", fim: "14:00", preco: 4.50)
    time_frame = TimeFrame.create!(turno: turno, inicio: "11:00", fim: "11:30")
    InscricaoFastpass.create!(
      usuario_matricula: usuario.matricula,
      sorteio: sorteio,
      time_frame: time_frame,
      resultado: InscricaoFastpass::RESULTADO_GANHOU,
      status_notificacao: "pendente"
    )
  end

  it "cria notificacao e marca inscricao como entregue" do
    allow(Time).to receive(:current).and_return(Time.zone.parse("2026-10-30 10:00:00"))

    resultado = described_class.call(inscricao: inscricao)

    expect(resultado).to be(true)
    expect(Notificacao.where(usuario_matricula: usuario.matricula).pluck(:mensagem))
      .to eq(["Parabéns! Você ganhou o FastPass."])
    expect(inscricao.reload.status_notificacao).to eq("entregue")
    expect(inscricao.notificada_em).to eq(Time.current)
  end

  it "nao cria notificacao quando a inscricao ainda nao tem resultado" do
    inscricao.update!(resultado: nil)

    expect(described_class.call(inscricao: inscricao)).to be(false)
    expect(Notificacao.count).to eq(0)
    expect(inscricao.reload.status_notificacao).to eq("pendente")
  end

  it "notifica resultado nao contemplado com o vocabulario canonico" do
    inscricao.update!(resultado: InscricaoFastpass::RESULTADO_NAO_GANHOU)

    expect(described_class.call(inscricao: inscricao)).to be(true)
    expect(Notificacao.last.mensagem).to eq("Você não foi contemplado no sorteio de FastPass.")
  end
end