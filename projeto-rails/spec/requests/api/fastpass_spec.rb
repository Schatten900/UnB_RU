require "rails_helper"

RSpec.describe "API de validação FastPass", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:agora) { Time.find_zone!("America/Sao_Paulo").local(2026, 11, 12, 12, 20) }
  let(:turno) { Turno.create!(nome: "Almoço", inicio: "11:00", fim: "14:00", preco: 4.50) }
  let(:restaurante) { Restaurante.create!(nome: "RU Darcy") }
  let(:catraca) { Catraca.create!(restaurante: restaurante, piso: 1, modo_acesso: "fastpass") }
  let(:funcionario) do
    Usuario.create!(matricula: "999123456", nome: "Operador", senha: "senha", turno: turno, saldo: 0)
  end
  let(:estudante) { Usuario.create!(matricula: "221012345", nome: "Aluno", senha: "senha", saldo: 20) }
  let(:janela) { TimeFrame.create!(turno: turno, inicio: "12:15", fim: "12:30") }
  let(:sorteio) { Sorteio.create!(data: agora.to_date, status: "concluido") }
  let!(:inscricao) do
    InscricaoFastpass.create!(usuario: estudante, time_frame: janela, sorteio: sorteio, resultado: "ganhou")
  end

  around { |exemplo| travel_to(agora) { exemplo.run } }

  def entrar(usuario = funcionario)
    post login_path, params: { matricula: usuario.matricula, senha: "senha" }
  end

  def configurar
    entrar
    post operator_ponto_configuracao_path, params: { restaurante_id: restaurante.id, catraca_id: catraca.id }
  end

  def validar(**extras)
    post "/api/fastpass/validacoes", params: { matricula: estudante.matricula }.merge(extras), as: :json
  end

  def confirmar(id)
    post "/api/fastpass/acessos/#{id}/confirmar", as: :json
  end

  def json
    JSON.parse(response.body)
  end

  it "exige sessão e impede uso por estudante em ambos os endpoints" do
    validar
    expect(response).to have_http_status(:unauthorized)
    confirmar(1)
    expect(response).to have_http_status(:unauthorized)
    entrar(estudante)
    validar
    expect(response).to have_http_status(:forbidden)
    confirmar(1)
    expect(response).to have_http_status(:forbidden)
    expect(Acesso.count).to eq(0)
  end

  it "exige ponto configurado e turno vinculado ao operador" do
    entrar
    validar
    expect(response).to have_http_status(:conflict)
    expect(json["motivo"]).to eq("contexto_nao_configurado")
    post operator_ponto_configuracao_path, params: { restaurante_id: restaurante.id, catraca_id: catraca.id }
    funcionario.update!(turno: nil)
    validar
    expect(response).to have_http_status(:conflict)
    expect(Acesso.count).to eq(0)
  end

  it "autoriza administrador com contexto configurado" do
    admin = Usuario.create!(matricula: "999912345", nome: "Admin", senha: "senha", turno: turno, saldo: 0)
    entrar(admin)
    post operator_ponto_configuracao_path, params: { restaurante_id: restaurante.id, catraca_id: catraca.id }
    validar
    expect(response).to have_http_status(:created)
  end

  it "valida, confirma e reflete a passagem nos históricos e no saldo, sem duplicar débito" do
    configurar
    expect { validar }.to change(Acesso, :count).by(1)
    expect(response).to have_http_status(:created)
    expect(json).to include("autorizado" => true, "motivo" => "autorizado", "status" => "pendente", "saldo" => "20.0", "valor_debitado" => "0.0")
    id = json.fetch("acesso_id")
    expect(estudante.historico_refeicoes).to be_empty
    expect { confirmar(id) }.to change { estudante.reload.saldo }.from(20).to(15.5)
    expect(response).to have_http_status(:ok)
    expect(json).to include("status" => "liberado", "valor_debitado" => "4.5", "saldo" => "15.5")
    expect(Acesso.find(id).passagem_em).to eq(agora)
    expect(estudante.historico_refeicoes.pluck(:id)).to eq([id])
    get operator_historico_local_path
    expect(response.body).to include(estudante.matricula, "Liberado")
    expect { confirmar(id) }.not_to change { estudante.reload.saldo }
    expect(response).to have_http_status(:conflict)
    expect(json["motivo"]).to eq("passagem_ja_confirmada")
    expect(Acesso.count).to eq(1)
  end

  {
    "sem inscrição" => :sem_inscricao,
    "não sorteado" => :nao_sorteado,
    "fora da janela" => :fora_da_janela,
    "sem saldo" => :saldo_insuficiente,
    "sorteio de outro dia" => :outro_dia,
    "inscrição de outro turno" => :outro_turno
  }.each do |descricao, cenario|
    it "registra bloqueio para #{descricao} e impede confirmação" do
      configurar
      motivo = case cenario
      when :sem_inscricao then inscricao.destroy!; "sem_fastpass"
      when :nao_sorteado then inscricao.update!(resultado: "nao_ganhou"); "sem_fastpass"
      when :fora_da_janela then janela.update!(inicio: "12:30", fim: "12:45"); "fora_da_janela"
      when :saldo_insuficiente then estudante.update!(saldo: 0); "saldo_insuficiente"
      when :outro_dia then sorteio.update!(data: agora.to_date - 1); "sem_fastpass"
      when :outro_turno
        outro = Turno.create!(nome: "Jantar", inicio: "17:00", fim: "20:00", preco: 4.50)
        janela.update!(turno: outro)
        "sem_fastpass"
      end
      saldo = estudante.reload.saldo
      expect { validar }.to change(Acesso, :count).by(1)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json).to include("autorizado" => false, "motivo" => motivo, "status" => "bloqueado")
      confirmar(json.fetch("acesso_id"))
      expect(response).to have_http_status(:conflict)
      expect(estudante.reload.saldo).to eq(saldo)
      expect(Acesso.last.passagem_em).to be_nil
    end
  end

  it "não aceita dados do cliente para trocar a catraca, turno, inscrição ou horário" do
    configurar
    validar(catraca_id: 99999, turno_id: 99999, inscricao_id: 99999, agora: "2000-01-01")
    expect(response).to have_http_status(:created)
    expect(Acesso.last.attributes).to include("catraca_id" => catraca.id, "turno_id" => turno.id,
                                            "inscricao_fastpass_id" => inscricao.id, "data_hora" => agora)
  end

  it "não confirma acesso de outra catraca nem uma tentativa comum" do
    configurar
    outra = Catraca.create!(restaurante: restaurante, piso: 2, modo_acesso: "fastpass")
    acesso = Acesso.create!(usuario: estudante, turno: turno, catraca: outra, data_hora: agora,
                           status: "pendente", inscricao_fastpass_id: inscricao.id)
    confirmar(acesso.id)
    expect(response).to have_http_status(:not_found)
    acesso.update!(catraca: catraca, inscricao_fastpass_id: nil)
    confirmar(acesso.id)
    expect(response).to have_http_status(:conflict)
    expect(estudante.reload.saldo).to eq(20)
  end

  it "não debita se o saldo cair entre validação e confirmação" do
    configurar
    validar
    id = json.fetch("acesso_id")
    estudante.update!(saldo: 0)
    confirmar(id)
    expect(response).to have_http_status(:unprocessable_content)
    expect(json["motivo"]).to eq("saldo_insuficiente")
    expect(Acesso.find(id).status).to eq("pendente")
    expect(Acesso.find(id).passagem_em).to be_nil
  end

  it "rejeita matrícula desconhecida e modo comum sem criar tentativa" do
    configurar
    validar(matricula: "000000000")
    expect(response).to have_http_status(:not_found)
    catraca.update!(modo_acesso: "normal")
    validar
    expect(response).to have_http_status(:conflict)
    expect(json["motivo"]).to eq("modo_nao_fastpass")
    expect(Acesso.count).to eq(0)
  end

  it "aceita refeição gratuita" do
    configurar
    turno.update!(preco: 0)
    validar
    expect(response).to have_http_status(:created)
    confirmar(json.fetch("acesso_id"))
    expect(response).to have_http_status(:ok)
    expect(estudante.reload.saldo).to eq(20)
    expect(Acesso.last.passagem_em).to be_present
  end
end
