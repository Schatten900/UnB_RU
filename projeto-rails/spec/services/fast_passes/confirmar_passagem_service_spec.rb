require "rails_helper"

RSpec.describe FastPasses::ConfirmarPassagemService, type: :service do
  let(:agora) { Time.find_zone!("America/Sao_Paulo").local(2026, 11, 13, 12, 5) }
  let(:estudante) { Usuario.create!(matricula: "232040501", nome: "Aluno", senha: "senha", saldo: 20) }
  let(:restaurante) { Restaurante.create!(nome: "RU") }
  let(:catraca) { restaurante.catracas.create!(piso: 1, modo_acesso: "fastpass") }
  let(:turno) { Turno.create!(nome: "Almoço", inicio: "11:00", fim: "14:00", preco: 4.5) }
  let(:janela) { turno.time_frames.create!(inicio: "12:00", fim: "12:15") }
  let!(:inscricao) do
    InscricaoFastpass.create!(usuario: estudante, catraca: catraca, time_frame: janela,
      sorteio: Sorteio.create!(data: agora.to_date, status: "concluido"), resultado: "ganhou")
  end

  def confirmar(instante: agora, ponto: catraca)
    described_class.new(estudante, ponto.id).call(agora: instante)
  end

  it "preserva os endpoints existentes com débito e faturamento na confirmação compartilhada" do
    acesso = confirmar
    expect(acesso.status).to eq("liberado")
    expect(acesso.passagem_em).to eq(agora)
    expect(estudante.reload.saldo).to eq(15.5)
    expect(restaurante.reload.faturamento).to eq(4.5)
    expect { confirmar }.to raise_error(described_class::PassagemNegada)
    expect(estudante.reload.saldo).to eq(15.5)
    expect(restaurante.reload.faturamento).to eq(4.5)
  end

  it "permite confirmar mesmo se já houver outra leitura pendente da inscrição" do
    leitura = Acesso.create!(usuario: estudante, catraca: catraca, turno: turno,
      inscricao_fastpass_id: inscricao.id, status: "pendente", data_hora: agora, valor_debitado: 0)
    confirmar
    expect(leitura.reload.passagem_em).to be_nil
    expect(inscricao.acessos.where.not(passagem_em: nil).count).to eq(1)
    expect(leitura.confirmar_passagem!(agora: agora)).to be(false)
    expect(restaurante.reload.faturamento).to eq(4.5)
  end

  it "rejeita o fim da janela, outra catraca e saldo insuficiente sem debitar" do
    expect { confirmar(instante: agora.change(min: 15)) }.to raise_error(described_class::PassagemNegada)
    outra = restaurante.catracas.create!(piso: 2, modo_acesso: "fastpass")
    expect { confirmar(ponto: outra) }.to raise_error(described_class::PassagemNegada)
    estudante.update!(saldo: 0)
    expect { confirmar }.to raise_error(described_class::PassagemNegada)
    expect(estudante.reload.saldo).to eq(0)
    expect(restaurante.reload.faturamento).to eq(0)
    expect(Acesso.where.not(passagem_em: nil)).to be_empty
  end
end
