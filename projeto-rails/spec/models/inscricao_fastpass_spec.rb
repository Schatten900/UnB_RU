require "rails_helper"

RSpec.describe "Inscrição única no FastPass", type: :model do
  let(:estudante) do
    Usuario.create!(
      matricula: "221012345", nome: "Estudante", senha_hash: "senha-hash",
      perfil: "estudante", saldo: "15.50"
    )
  end
  let(:sorteio) { Sorteio.create!(data: Date.new(2026, 10, 16), status: "aberto") }
  let(:almoco) { Turno.create!(nome: "Almoço", inicio: "11:00", fim: "14:30", preco: "4.50") }
  let(:jantar) { Turno.create!(nome: "Jantar", inicio: "18:00", fim: "19:30", preco: "4.50") }
  let(:primeiro_horario) { TimeFrame.create!(turno: almoco, inicio: "12:00", fim: "12:30") }
  let(:segundo_horario) { TimeFrame.create!(turno: almoco, inicio: "12:30", fim: "13:00") }
  let(:horario_jantar) { TimeFrame.create!(turno: jantar, inicio: "18:00", fim: "18:30") }

  def nova_inscricao(horario)
    InscricaoFastpass.new(usuario: estudante, sorteio: sorteio, time_frame: horario)
  end

  it "confirma a primeira inscrição no time-frame escolhido" do
    inscricao = nova_inscricao(primeiro_horario)

    expect { expect(inscricao.save).to be(true) }.to change { InscricaoFastpass.count }.by(1)
    expect(inscricao.reload.usuario_matricula).to eq(estudante.matricula)
    expect(inscricao.sorteio_id).to eq(sorteio.id)
    expect(inscricao.time_frame_id).to eq(primeiro_horario.id)
    expect(estudante.reload.saldo).to eq(BigDecimal("15.50"))
  end

  it "permite inscrições no Almoço e no Jantar do mesmo sorteio" do
    original = nova_inscricao(primeiro_horario)
    original.save!
    inscricao_jantar = nova_inscricao(horario_jantar)

    expect { expect(inscricao_jantar.save).to be(true) }.to change { InscricaoFastpass.count }.by(1)
    expect(InscricaoFastpass.where(usuario_matricula: estudante.matricula, sorteio_id: sorteio.id)
                           .pluck(:time_frame_id)).to match_array([primeiro_horario.id, horario_jantar.id])
    expect(original.reload.time_frame_id).to eq(primeiro_horario.id)
  end

  it "permite inscrição gratuita com saldo zero" do
    estudante.update!(saldo: 0)
    inscricao = nova_inscricao(primeiro_horario)

    expect { expect(inscricao.save).to be(true) }.to change { InscricaoFastpass.count }.by(1)
    expect(inscricao.reload).to be_persisted
    expect(estudante.reload.saldo).to eq(0.to_d)
  end

  it "recusa outro time-frame do mesmo turno e preserva a inscrição original" do
    original = nova_inscricao(primeiro_horario)
    original.save!
    atributos_originais = original.reload.attributes
    duplicada = nova_inscricao(segundo_horario)

    expect { expect(duplicada.save).to be(false) }.not_to change { InscricaoFastpass.count }
    expect(duplicada.errors).not_to be_empty
    expect(duplicada).not_to be_persisted
    expect(original.reload.attributes).to eq(atributos_originais)
    expect(InscricaoFastpass.where(usuario_matricula: estudante.matricula, sorteio_id: sorteio.id)
                           .pluck(:time_frame_id)).to eq([primeiro_horario.id])
  end

  it "recusa inscrição sem time-frame e informa a escolha obrigatória" do
    inscricao = nova_inscricao(nil)

    expect { expect(inscricao.save).to be(false) }.not_to change { InscricaoFastpass.count }
    expect(inscricao.errors[:time_frame]).not_to be_empty
    expect(inscricao).not_to be_persisted
  end
end
