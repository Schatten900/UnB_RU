require "rails_helper"

RSpec.describe "Gestao de Turnos e Time-frames (US14)", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:administrador) do
    Usuario.create!(matricula: "999900001", nome: "Admin", senha: "Senha123!", saldo: 0)
  end
  let(:estudante) do
    Usuario.create!(matricula: "221012345", nome: "Estudante", senha: "Senha123!", saldo: 0)
  end
  let(:turno) do
    Turno.create!(nome: "Almoco", inicio: "11:00", fim: "14:00", preco: "4.50")
  end
  let(:dados) do
    { nome: "Almoco", inicio: "11:00", fim: "14:00", preco: "4.50" }
  end

  def autenticar(usuario = administrador)
    post login_path, params: { matricula: usuario.matricula, senha: "Senha123!" }
  end

  def gerar_janelas(turno_alvo = turno, duracao = 15)
    Turnos::GerarTimeframe.new(turno_alvo, duracao).call
    turno_alvo.reload
  end

  it "exige autenticacao para consultar a pagina e cadastrar turnos" do
    get admin_turnos_path
    expect(response).to redirect_to(login_path)

    expect do
      post admin_turnos_path, params: { turno: dados, duracao_intervalo: "15" }
    end.not_to change(Turno, :count)
    expect(response).to redirect_to(login_path)
  end

  it "impede acesso de estudantes" do
    autenticar(estudante)

    get admin_turnos_path
    expect(response).to redirect_to(login_path)

    expect do
      post admin_turnos_path, params: { turno: dados, duracao_intervalo: "15" }
    end.not_to change(Turno, :count)
  end

  it "impede acesso de funcionarios que nao sao administradores" do
    expediente = Turno.create!(nome: "Expediente", inicio: "09:00", fim: "17:00", preco: 0)
    funcionario = Usuario.create!(
      matricula: "999123456", nome: "Funcionario", senha: "Senha123!",
      saldo: 0, turno: expediente
    )

    travel_to(Time.find_zone!("America/Sao_Paulo").local(2026, 10, 15, 12, 0)) do
      autenticar(funcionario)
      get admin_turnos_path
      expect(response).to redirect_to(login_path)
    end
  end

  it "exibe o estado vazio e o formulario de cadastro" do
    autenticar

    get admin_turnos_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Nenhum turno cadastrado", "Cadastrar novo turno")
  end

  it "lista turnos e suas janelas, selecionando um turno via parametro" do
    primeiro = turno
    gerar_janelas(primeiro)
    segundo = Turno.create!(nome: "Jantar", inicio: "17:30", fim: "19:30", preco: "4.50")
    gerar_janelas(segundo, 30)
    autenticar

    get admin_turnos_path(turno_id: segundo.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Almoco", "Jantar", "Time-frames")
    expect(response.body).to include("Turno selecionado:", "17:30", "Lote 04")
  end

  it "cadastra turno e gera intervalos de 15 minutos" do
    autenticar

    expect do
      post admin_turnos_path, params: { turno: dados, duracao_intervalo: "15" }
    end.to change(Turno, :count).by(1).and change(TimeFrame, :count).by(12)

    novo = Turno.last
    expect(response).to redirect_to(admin_turnos_path(turno_id: novo.id))
    expect(novo.time_frames.order(:inicio).first.inicio.strftime("%H:%M")).to eq("11:00")
    expect(novo.time_frames.order(:inicio).last.fim.strftime("%H:%M")).to eq("14:00")
  end

  it "gera a ultima janela com duracao menor quando necessario" do
    autenticar

    post admin_turnos_path, params: {
      turno: dados.merge(inicio: "11:00", fim: "11:50"),
      duracao_intervalo: "30"
    }

    expect(response).to have_http_status(:redirect)
    janelas = Turno.last.time_frames.order(:inicio)
    expect(janelas.size).to eq(2)
    expect(janelas.last.inicio.strftime("%H:%M")).to eq("11:30")
    expect(janelas.last.fim.strftime("%H:%M")).to eq("11:50")
  end

  it "nao cadastra turno com duracao invalida" do
    autenticar

    expect do
      post admin_turnos_path, params: { turno: dados, duracao_intervalo: "0" }
    end.not_to change(Turno, :count)

    follow_redirect!
    expect(response.body).to include("tf-notice-error")
  end

  it "nao cadastra turno com intervalo invertido" do
    autenticar

    expect do
      post admin_turnos_path, params: {
        turno: dados.merge(inicio: "14:00", fim: "11:00"), duracao_intervalo: "15"
      }
    end.not_to change(Turno, :count)

    expect(response).to redirect_to(admin_turnos_path)
  end

  it "nao cadastra turno sem nome" do
    autenticar

    expect do
      post admin_turnos_path, params: { turno: dados.merge(nome: ""), duracao_intervalo: "15" }
    end.not_to change(Turno, :count)
    expect(TimeFrame.count).to eq(0)
  end

  it "edita horarios e regenera janelas quando necessario" do
    alvo = turno
    gerar_janelas(alvo)
    autenticar

    patch admin_turno_path(alvo), params: {
      turno: dados.merge(nome: "Almoco atualizado", fim: "12:00", preco: "5.00"),
      duracao_intervalo: "20"
    }

    expect(response).to redirect_to(admin_turnos_path(turno_id: alvo.id))
    expect(alvo.reload.nome).to eq("Almoco atualizado")
    expect(alvo.preco).to eq(5.to_d)
    expect(alvo.time_frames.count).to eq(3)
    expect(alvo.time_frames.order(:inicio).last.fim.strftime("%H:%M")).to eq("12:00")
  end

  it "atualiza apenas nome e preco sem recriar os intervalos" do
    alvo = turno
    gerar_janelas(alvo)
    ids = alvo.time_frames.order(:id).pluck(:id)
    autenticar

    patch admin_turno_path(alvo), params: {
      turno: dados.merge(nome: "Almoco revisado", preco: "3.00"),
      duracao_intervalo: "15"
    }

    expect(response).to redirect_to(admin_turnos_path(turno_id: alvo.id))
    expect(alvo.reload.nome).to eq("Almoco revisado")
    expect(alvo.preco).to eq(3.to_d)
    expect(alvo.time_frames.order(:id).pluck(:id)).to eq(ids)
  end

  it "rejeita duracao invalida sem alterar o turno existente" do
    alvo = turno
    gerar_janelas(alvo)
    autenticar

    patch admin_turno_path(alvo), params: {
      turno: dados.merge(nome: "Novo nome"), duracao_intervalo: "abc"
    }

    expect(response).to redirect_to(admin_turnos_path(turno_id: alvo.id))
    expect(alvo.reload.nome).to eq("Almoco")
    expect(alvo.time_frames.count).to eq(12)
  end

  it "nao altera horarios nem apaga janelas vinculadas a inscricoes FastPass" do
    alvo = turno
    gerar_janelas(alvo)
    janela = alvo.time_frames.first
    sorteio = Sorteio.create!(data: Date.new(2026, 10, 15), status: "aberto")
    InscricaoFastpass.create!(usuario: estudante, sorteio: sorteio,
                             time_frame: janela, resultado: "ganhou")
    ids = alvo.time_frames.order(:id).pluck(:id)
    autenticar

    patch admin_turno_path(alvo), params: {
      turno: dados.merge(inicio: "11:30", fim: "14:30"),
      duracao_intervalo: "15"
    }

    expect(response).to redirect_to(admin_turnos_path(turno_id: alvo.id))
    expect(alvo.reload.inicio.strftime("%H:%M")).to eq("11:00")
    expect(alvo.time_frames.order(:id).pluck(:id)).to eq(ids)
    expect(InscricaoFastpass.count).to eq(1)
    follow_redirect!
    expect(response.body).to include("inscricoes FastPass")
  end

  it "permite mudar o preco de um turno com inscricoes sem recriar janelas" do
    alvo = turno
    gerar_janelas(alvo)
    sorteio = Sorteio.create!(data: Date.new(2026, 10, 15), status: "aberto")
    InscricaoFastpass.create!(usuario: estudante, sorteio: sorteio,
                             time_frame: alvo.time_frames.first, resultado: "ganhou")
    ids = alvo.time_frames.order(:id).pluck(:id)
    autenticar

    patch admin_turno_path(alvo), params: {
      turno: dados.merge(preco: "6.00"), duracao_intervalo: "15"
    }

    expect(response).to redirect_to(admin_turnos_path(turno_id: alvo.id))
    expect(alvo.reload.preco).to eq(6.to_d)
    expect(alvo.time_frames.order(:id).pluck(:id)).to eq(ids)
  end
end
