require "rails_helper"

RSpec.describe "Historico Local de Acessos (US12)", type: :request do
  let(:agora) { Time.find_zone!("America/Sao_Paulo").local(2026, 10, 30, 12, 30) }
  let(:turno) { Turno.create!(nome: "Almoco", inicio: "11:00", fim: "14:30", preco: "4.50") }
  let(:funcionario) do
    Usuario.create!(
      matricula: "999123456", nome: "Funcionario do RU", senha: "senha-segura",
      turno: turno, saldo: 0
    )
  end
  let(:estudante) do
    Usuario.create!(matricula: "221012345", nome: "Aluno A", senha: "senha-segura", saldo: 15.50)
  end
  let(:outro_estudante) do
    Usuario.create!(matricula: "231045229", nome: "Aluno B", senha: "senha-segura", saldo: 3.50)
  end
  let(:terceiro_estudante) do
    Usuario.create!(matricula: "251123339", nome: "Aluno C", senha: "senha-segura", saldo: 0)
  end
  let(:restaurante) { Restaurante.create!(nome: "RU Darcy Ribeiro") }
  let(:catraca) { restaurante.catracas.create!(piso: 2, modo_acesso: "normal") }
  let(:outra_catraca) { restaurante.catracas.create!(piso: 1, modo_acesso: "fastpass") }

  before { allow(Time).to receive(:current).and_return(agora) }

  def entrar_como_funcionario
    post login_path, params: { matricula: funcionario.matricula, senha: "senha-segura" }
    expect(response).to redirect_to(ponto_configuracao_path)
  end

  def configurar_ponto
    entrar_como_funcionario
    post ponto_configuracao_path, params: {
      restaurante_id: restaurante.id,
      catraca_id: catraca.id
    }
    expect(response).to redirect_to(ponto_configuracao_path)
  end

  def tentativa(usuario:, catraca_alvo: catraca, status:, minutos_atras: 0,
               debito: 0, inscricao_fastpass_id: nil)
    horario = agora - minutos_atras.minutes
    Acesso.create!(
      usuario: usuario, turno: turno, catraca: catraca_alvo,
      data_hora: horario, status: status,
      passagem_em: status == "liberado" ? horario : nil,
      valor_debitado: debito,
      inscricao_fastpass_id: inscricao_fastpass_id
    )
  end

  it "exige autenticacao" do
    get historico_local_path
    expect(response).to redirect_to(login_path)
  end

  it "exige ponto de acesso configurado na sessao" do
    entrar_como_funcionario

    get historico_local_path
    expect(response).to redirect_to(ponto_configuracao_path)
  end

  it "exibe o restaurante e a catraca configurados" do
    configurar_ponto

    get historico_local_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Histórico Local da Catraca")
    expect(response.body).to include("RU Darcy Ribeiro")
    expect(response.body).to include("Piso 2")
  end

  it "adiciona acesso ao historico no menu da configuracao de ponto" do
    configurar_ponto

    get ponto_configuracao_path
    expect(response.body).to include("Histórico Local")
  end

  it "lista tentativas da catraca selecionada, inclusive bloqueadas e pendentes" do
    configurar_ponto
    tentativa(usuario: estudante, status: "liberado", minutos_atras: 3, debito: 4.50)
    tentativa(usuario: outro_estudante, status: "bloqueado", minutos_atras: 2)
    tentativa(usuario: terceiro_estudante, catraca_alvo: outra_catraca, status: "pendente")

    get historico_local_path
    expect(response.body).to include("221012345", "231045229", "Liberado", "Bloqueado")
    expect(response.body).not_to include("251123339")
    expect(response.body.index("231045229")).to be < response.body.index("221012345")
  end

  it "filtra por status" do
    configurar_ponto
    tentativa(usuario: estudante, status: "liberado", debito: 4.50)
    tentativa(usuario: outro_estudante, status: "bloqueado", minutos_atras: 1)

    get historico_local_path, params: { status: "bloqueado" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("231045229")
    expect(response.body).not_to include("221012345")
  end

  it "filtra por vinculo real com inscricao FastPass" do
    configurar_ponto
    sorteio = Sorteio.create!(data: agora.to_date, status: "aberto")
    intervalo = TimeFrame.create!(turno: turno, inicio: "12:15", fim: "12:45")
    inscricao = InscricaoFastpass.create!(
      usuario: estudante, sorteio: sorteio, time_frame: intervalo, resultado: "ganhou"
    )
    tentativa(usuario: estudante, status: "liberado", debito: 4.50,
              inscricao_fastpass_id: inscricao.id)
    tentativa(usuario: outro_estudante, status: "bloqueado", minutos_atras: 2)

    get historico_local_path, params: { vinculo: "fastpass" }
    expect(response.body).to include("221012345", "FastPass vinculado")
    expect(response.body).not_to include("231045229")
  end

  it "calcula indicadores apenas com registros do dia" do
    configurar_ponto
    tentativa(usuario: estudante, status: "liberado", debito: 4.50)
    tentativa(usuario: outro_estudante, status: "bloqueado", minutos_atras: 2)
    # Registro antigo nao entra nas metricas de hoje.
    Acesso.create!(
      usuario: estudante, turno: turno, catraca: catraca,
      data_hora: agora - 2.days, passagem_em: agora - 2.days,
      status: "liberado", valor_debitado: 20
    )

    get historico_local_path
    expect(response.body).to include("Passagens Confirmadas", "Tentativas Rejeitadas")
    expect(response.body).to include("R$ 4,50")
  end

  it "exporta todos os registros filtrados em CSV sem aplicar paginacao" do
    configurar_ponto
    12.times do |i|
      tentativa(usuario: estudante, status: "liberado", minutos_atras: i, debito: 4.50)
    end
    tentativa(usuario: outro_estudante, status: "bloqueado", minutos_atras: 20)

    get exportar_historico_local_path, params: { formato: "csv", status: "liberado" }
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/csv")
    expect(response.headers["Content-Disposition"]).to include("attachment")
    expect(response.body.lines.size).to eq(13) # cabecalho e 12 entradas
    expect(response.body).not_to include("231045229")
  end

  it "exporta um PDF valido" do
    configurar_ponto
    tentativa(usuario: estudante, status: "liberado", debito: 4.50)

    get exportar_historico_local_path, params: { formato: "pdf" }
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/pdf")
    expect(response.body.start_with?("%PDF-")).to be(true)
  end

  it "pagina a listagem em grupos de dez" do
    configurar_ponto
    12.times do |i|
      tentativa(usuario: estudante, status: "liberado", minutos_atras: i, debito: 4.50)
    end

    get historico_local_path, params: { pagina: 2 }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Página 2 de 2")
    expect(response.body).to include("11 a 12 de 12")
  end
end
