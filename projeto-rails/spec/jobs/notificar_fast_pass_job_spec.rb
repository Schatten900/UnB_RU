require "rails_helper"

RSpec.describe NotificarFastPassJob, type: :job do
  it "notifica inscricao pendente de sorteio para turno que comeca em uma hora" do
    agora = Time.utc(2026, 10, 30, 14, 0)
    allow(Time).to receive(:current).and_return(agora)
    usuario = Usuario.create!(
      matricula: "221012345",
      nome: "Estudante",
      senha_hash: "hash",
      perfil: "estudante",
      saldo: 0
    )
    sorteio = Sorteio.create!(data: Date.new(2026, 10, 30), status: "concluido")
    turno = Turno.create!(nome: "Almoco", inicio: "12:00", fim: "14:00", preco: 4.50)
    time_frame = TimeFrame.create!(turno: turno, inicio: "12:00", fim: "12:30")
    inscricao = InscricaoFastpass.create!(
      usuario_matricula: usuario.matricula,
      sorteio: sorteio,
      time_frame: time_frame,
      resultado: InscricaoFastpass::RESULTADO_NAO_GANHOU,
      status_notificacao: "pendente"
    )

    described_class.perform_now

    expect(Notificacao.where(usuario_matricula: usuario.matricula).pluck(:mensagem))
      .to eq(["Você não foi contemplado no sorteio de FastPass."])
    expect(inscricao.reload.status_notificacao).to eq("entregue")
  end

  it "notifica as inscricoes do sorteio concluido quando recebe seu id" do
    usuario = Usuario.create!(
      matricula: "221012345",
      nome: "Estudante",
      senha_hash: "hash",
      perfil: "estudante",
      saldo: 0
    )
    sorteio = Sorteio.create!(data: Date.current, status: "concluido")
    turno = Turno.create!(nome: "Almoco", inicio: "12:00", fim: "14:00", preco: 4.50)
    time_frame = TimeFrame.create!(turno: turno, inicio: "12:00", fim: "12:30")
    inscricao = InscricaoFastpass.create!(
      usuario_matricula: usuario.matricula,
      sorteio: sorteio,
      time_frame: time_frame,
      resultado: InscricaoFastpass::RESULTADO_GANHOU,
      status_notificacao: "pendente"
    )

    described_class.perform_now(sorteio.id)

    expect(Notificacao.where(usuario_matricula: usuario.matricula).pluck(:mensagem))
      .to eq(["Parabéns! Você ganhou o FastPass."])
    expect(inscricao.reload.status_notificacao).to eq("entregue")
  end
end