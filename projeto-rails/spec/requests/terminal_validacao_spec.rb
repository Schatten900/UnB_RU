require "rails_helper"

RSpec.describe "Terminal de validação", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:turno) { Turno.create!(nome: "Almoço", inicio: "11:00", fim: "14:30", preco: "4.50") }
  let(:funcionario) do
    Usuario.create!(matricula: "999123456", nome: "Fiscal", senha: "senha-segura", turno: turno, saldo: 0)
  end

  def autenticar
    travel_to(Time.find_zone!("America/Sao_Paulo").local(2026, 11, 8, 12)) do
      post login_path, params: { matricula: funcionario.matricula, senha: "senha-segura" }
    end
  end

  it "protege terminal de acesso sem autenticação" do
    get operator_terminal_validacao_path
    expect(response).to redirect_to(login_path)
  end

  it "exibe as três abas e o simulador sem alterar dados" do
    autenticar
    get operator_terminal_validacao_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Configuração de Ponto", "Terminal de Validação", "Histórico Local")
    expect(response.body).to include('aria-current="page"', "Identificação recebida na leitura", "Aguardando identificação")
    expect(response.body).to include("Processar leitura", operator_processar_leitura_path)

    get operator_ponto_configuracao_path
    expect(response.body).to include(operator_terminal_validacao_path, "Configure um restaurante e uma catraca para acessar o histórico")
  end

  it "mostra somente os acessos da catraca selecionada" do
    autenticar
    restaurante = Restaurante.create!(nome: "RU de teste")
    catraca = restaurante.catracas.create!(piso: 1, modo_acesso: "normal")
    outra = restaurante.catracas.create!(piso: 2, modo_acesso: "normal")
    aluno = Usuario.create!(matricula: "221012345", nome: "Estudante visível", senha: "senha", saldo: 20)
    outro = Usuario.create!(matricula: "231045229", nome: "Estudante oculto", senha: "senha", saldo: 20)
    Acesso.create!(usuario: aluno, turno: turno, catraca: catraca, data_hora: Time.current, status: "liberado")
    Acesso.create!(usuario: outro, turno: turno, catraca: outra, data_hora: Time.current, status: "liberado")
    post operator_ponto_configuracao_path, params: { restaurante_id: restaurante.id, catraca_id: catraca.id }

    get operator_terminal_validacao_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Estudante visível")
    expect(response.body).not_to include("Estudante oculto")
    expect(response.body).to include(%(href="#{operator_historico_local_path}"))
  end

  context "simulações e processamento da leitura" do
    include ActiveSupport::Testing::TimeHelpers

    let(:turno) { Turno.create!(nome: "Almoço", inicio: "11:00", fim: "14:30", preco: 4.50) }
    let(:operador) { Usuario.create!(matricula: "999123456", nome: "Fiscal", senha: "senha-segura", saldo: 0, turno: turno) }
    let(:restaurante) { Restaurante.create!(nome: "RU de teste") }
    let(:catraca) { restaurante.catracas.create!(piso: 1, modo_acesso: "normal") }
    let!(:estudante) { Usuario.create!(matricula: "221012345", nome: "Estudante com saldo", senha: "senha", saldo: 30) }
    let!(:sem_saldo) { Usuario.create!(matricula: "221012346", nome: "Estudante sem saldo", senha: "senha", saldo: 0) }
    let!(:fora_janela) { Usuario.create!(matricula: "221012347", nome: "Estudante fora da janela", senha: "senha", saldo: 30) }
    let(:sorteio) { Sorteio.create!(data: Time.current.in_time_zone("America/Sao_Paulo").to_date, status: "finalizado") }
    let(:janela_atual) { TimeFrame.create!(turno: turno, inicio: "12:15", fim: "12:30") }
    let(:janela_passada) { TimeFrame.create!(turno: turno, inicio: "11:00", fim: "11:15") }

    around do |exemplo|
      travel_to(Time.find_zone!("America/Sao_Paulo").local(2026, 11, 11, 12, 20)) { exemplo.run }
    end

    before do
      post login_path, params: { matricula: operador.matricula, senha: "senha-segura" }
      post operator_ponto_configuracao_path, params: { restaurante_id: restaurante.id, catraca_id: catraca.id }
      [[estudante, janela_atual], [sem_saldo, janela_atual], [fora_janela, janela_passada]].each do |usuario, janela|
        InscricaoFastpass.create!(usuario: usuario, sorteio: sorteio, time_frame: janela,
                                 resultado: InscricaoFastpass::RESULTADO_GANHOU, status_notificacao: "pendente")
      end
    end

    def resposta
      JSON.parse(response.body)
    end

    def simular(acao = "simular_ok", modo = "normal", matricula: nil)
      post "/operator/terminal_validacao/#{acao}", params: { modo: modo, matricula: matricula }, as: :json
    end

    it "processa a matrícula e só debita após confirmar manualmente a passagem" do
      expect {
        simular("processar_leitura", "normal", matricula: estudante.matricula)
      }.to change(Acesso, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(resposta["estudante"]["matricula"]).to eq(estudante.matricula)
      expect(resposta["estudante"]["saldo"]).to eq(30)
      expect(resposta["confirmado"]).to be(false)
      expect(Acesso.last.status).to eq("pendente")
      expect(estudante.reload.saldo).to eq(30)

      autorizacao = resposta.fetch("autorizacao")
      post operator_confirmar_passagem_path, params: { autorizacao: autorizacao }, as: :json

      expect(response).to have_http_status(:ok)
      expect(resposta["confirmado"]).to be(true)
      expect(estudante.reload.saldo).to eq(25.5.to_d)
      expect(Acesso.last.passagem_em).to be_present
    end

    it "processa a leitura conforme o modo FastPass selecionado" do
      simular("processar_leitura", "fastpass", matricula: estudante.matricula)

      expect(response).to have_http_status(:ok)
      expect(resposta["modo"]).to eq("fastpass")
      expect(resposta["autorizado"]).to be(true)
      expect(resposta["janela"]).to eq("12:15 – 12:30")
      expect(estudante.reload.saldo).to eq(30)
    end

    it "processa uma leitura fora da janela e mantém a confirmação bloqueada" do
      simular("processar_leitura", "fastpass", matricula: fora_janela.matricula)

      expect(response).to have_http_status(:ok)
      expect(resposta["motivo"]).to eq("fora_da_janela")
      expect(resposta["autorizacao"]).to be_nil
      expect(Acesso.last.status).to eq("bloqueado")
      expect(fora_janela.reload.saldo).to eq(30)
    end

    it "exige matrícula no processamento da leitura, sem selecionar outro aluno automaticamente" do
      expect {
        simular("processar_leitura", "normal", matricula: "   ")
      }.not_to change(Acesso, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(resposta["erro"]).to include("Informe a matrícula")
    end

    it "seleciona um estudante existente e registra a leitura sem criar dados auxiliares nem debitar" do
      contagens = [Usuario.count, Sorteio.count, InscricaoFastpass.count, TimeFrame.count]

      expect { simular }.to change(Acesso, :count).by(1)

      expect(response).to have_http_status(:ok)
      acesso = Acesso.last
      expect(acesso.status).to eq("pendente")
      expect(acesso.passagem_em).to be_nil
      expect(acesso.valor_debitado).to eq(0)
      expect(acesso.usuario_matricula).to eq(estudante.matricula)
      expect(resposta["autorizado"]).to be(true)
      expect(resposta["registros_html"]).to include(acesso.usuario_matricula, "Pendente")
      expect(estudante.reload.saldo).to eq(30)
      expect([Usuario.count, Sorteio.count, InscricaoFastpass.count, TimeFrame.count]).to eq(contagens)
    end

    it "seleciona um vencedor existente com saldo e janela atual no modo FastPass" do
      contagens = [Usuario.count, Sorteio.count, InscricaoFastpass.count, TimeFrame.count]
      simular("simular_ok", "fastpass")

      expect(response).to have_http_status(:ok)
      expect(resposta["modo"]).to eq("fastpass")
      expect(resposta["autorizado"]).to be(true)
      expect(Acesso.last.inscricao_fastpass_id).to be_present
      expect(resposta["janela"]).to eq("12:15 – 12:30")
      expect(catraca.reload.modo_acesso).to eq("normal")
      expect(Acesso.last.usuario_matricula).to eq(estudante.matricula)
      expect([Usuario.count, Sorteio.count, InscricaoFastpass.count, TimeFrame.count]).to eq(contagens)
    end

    it "registra bloqueio fora da janela sem permitir débito" do
      simular("simular_fora_janela")

      expect(response).to have_http_status(:ok)
      expect(resposta["modo"]).to eq("fastpass")
      expect(resposta["motivo"]).to eq("fora_da_janela")
      expect(resposta["autorizado"]).to be(false)
      expect(resposta["autorizacao"]).to be_nil
      expect(Acesso.last.status).to eq("bloqueado")
      expect(Acesso.last.usuario_matricula).to eq(fora_janela.matricula)
      expect(Acesso.last.valor_debitado).to eq(0)
      expect(resposta["registros_html"]).to include("Bloqueado", "FastPass")
    end

    %w[normal fastpass].each do |modo|
      it "registra falta de saldo no modo #{modo}" do
        simular("simular_sem_saldo", modo)

        expect(response).to have_http_status(:ok)
        expect(resposta["motivo"]).to eq("saldo_insuficiente")
        expect(resposta["autorizado"]).to be(false)
        expect(Acesso.last.usuario.saldo).to eq(0)
        expect(Acesso.last.usuario_matricula).to eq(sem_saldo.matricula)
        expect(Acesso.last.status).to eq("bloqueado")
      end
    end

    it "simula modo comum mesmo quando o toggle estava em FastPass" do
      simular("simular_modo_comum", "fastpass")

      expect(response).to have_http_status(:ok)
      expect(resposta["modo"]).to eq("normal")
      expect(Acesso.last.inscricao_fastpass_id).to be_nil
      expect(resposta["autorizado"]).to be(true)
    end

    it "confirma uma passagem uma única vez e atualiza o mesmo registro da tabela" do
      simular("simular_ok", "fastpass")
      autorizacao = resposta.fetch("autorizacao")
      acesso = Acesso.last
      saldo_inicial = acesso.usuario.saldo
      confirmar = "/operator/terminal_validacao/confirmar_passagem"

      expect {
        post confirmar, params: { autorizacao: autorizacao }, as: :json
      }.not_to change(Acesso, :count)

      expect(response).to have_http_status(:ok)
      expect(resposta["confirmado"]).to be(true)
      expect(resposta["registros_html"]).to include("Liberado", "4,50")
      expect(acesso.reload.passagem_em).to eq(Time.current)
      expect(acesso.usuario.reload.saldo).to eq(saldo_inicial - turno.preco)

      post confirmar, params: { autorizacao: autorizacao }, as: :json
      expect(response).to have_http_status(:conflict)
      expect(acesso.usuario.reload.saldo).to eq(saldo_inicial - turno.preco)
    end

    it "não confirma uma leitura emitida para outra catraca" do
      simular
      autorizacao = resposta.fetch("autorizacao")
      acesso = Acesso.last
      outra = restaurante.catracas.create!(piso: 2, modo_acesso: "normal")
      post operator_ponto_configuracao_path, params: { restaurante_id: restaurante.id, catraca_id: outra.id }

      post "/operator/terminal_validacao/confirmar_passagem", params: { autorizacao: autorizacao }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(acesso.reload.passagem_em).to be_nil
      expect(acesso.valor_debitado).to eq(0)
    end

    it "desfaz a reserva da passagem se o saldo mudar antes da confirmação" do
      simular
      autorizacao = resposta.fetch("autorizacao")
      acesso = Acesso.last
      acesso.usuario.update!(saldo: 0)

      post "/operator/terminal_validacao/confirmar_passagem", params: { autorizacao: autorizacao }, as: :json

      expect(response).to have_http_status(:conflict)
      expect(acesso.reload.status).to eq("pendente")
      expect(acesso.passagem_em).to be_nil
      expect(acesso.valor_debitado).to eq(0)
    end

    it "simula FastPass também na última janela do dia" do
      travel_to(Time.find_zone!("America/Sao_Paulo").local(2026, 11, 11, 23, 59, 30))
      janela_atual.update!(inicio: "23:45", fim: "23:59:59.999999")
      simular("simular_ok", "fastpass")

      expect(response).to have_http_status(:ok)
      expect(resposta["autorizado"]).to be(true)
    end

    it "não aceita um token de confirmação adulterado" do
      simular
      acesso = Acesso.last
      post "/operator/terminal_validacao/confirmar_passagem", params: { autorizacao: "token-adulterado" }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(acesso.reload.passagem_em).to be_nil
    end

    it "rejeita modos inválidos sem criar contas ou registros" do
      expect { simular("simular_ok", "invalido") }.not_to change(Usuario, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(Acesso.count).to eq(0)
    end

    it "exige ponto configurado antes de simular" do
      delete logout_path
      post login_path, params: { matricula: operador.matricula, senha: "senha-segura" }

      expect { simular }.not_to change(Acesso, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(resposta["erro"]).to include("Configure")
    end

    it "exige autenticação para registrar tentativas" do
      delete logout_path

      expect { simular }.not_to change(Acesso, :count)
      expect(response).to redirect_to(login_path)
    end

    it "prioriza a matrícula lida, mesmo que outro estudante venha antes na busca automática" do
      simular("simular_ok", "normal", matricula: fora_janela.matricula)

      expect(response).to have_http_status(:ok)
      expect(Acesso.last.usuario_matricula).to eq(fora_janela.matricula)
      expect(resposta["origem_leitura"]).to eq("informada")
    end

    it "trata uma leitura vazia como seleção automática" do
      simular("simular_ok", "normal", matricula: "   ")

      expect(response).to have_http_status(:ok)
      expect(Acesso.last.usuario_matricula).to eq(estudante.matricula)
      expect(resposta["origem_leitura"]).to eq("automatica")
    end

    it "registra bloqueio quando a matrícula lida não possui FastPass válido" do
      InscricaoFastpass.where(usuario_matricula: estudante.matricula).destroy_all
      saldo_inicial = estudante.saldo

      expect {
        simular("simular_ok", "fastpass", matricula: estudante.matricula)
      }.to change(Acesso, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(resposta["motivo"]).to eq("sem_fastpass")
      expect(resposta["autorizado"]).to be(false)
      expect(resposta["registros_html"]).to include("Sem vínculo FastPass", "Bloqueado")
      expect(estudante.reload.saldo).to eq(saldo_inicial)
    end

    it "valida o saldo real da matrícula lida em vez de fabricar um resultado OK" do
      simular("simular_ok", "normal", matricula: sem_saldo.matricula)

      expect(response).to have_http_status(:ok)
      expect(Acesso.last.usuario_matricula).to eq(sem_saldo.matricula)
      expect(resposta["autorizado"]).to be(false)
      expect(resposta["motivo"]).to eq("saldo_insuficiente")
    end

    it "não substitui uma identificação desconhecida por outro estudante" do
      expect { simular("simular_ok", "normal", matricula: "123123123") }.not_to change(Acesso, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(resposta["erro"]).to include("matrícula")
    end

    it "rejeita leitura de funcionário ou administrador" do
      expect { simular("simular_ok", "normal", matricula: operador.matricula) }.not_to change(Acesso, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "não fabrica estudante quando ninguém tem saldo para o cenário" do
      Usuario.where(perfil: "estudante").update_all(saldo: 0)
      contagens = [Usuario.count, Sorteio.count, InscricaoFastpass.count, TimeFrame.count]

      expect { simular }.not_to change(Acesso, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(resposta["erro"]).to include("Nenhum estudante")
      expect([Usuario.count, Sorteio.count, InscricaoFastpass.count, TimeFrame.count]).to eq(contagens)
    end

    it "ignora inscrições de outra data na seleção automática" do
      sorteio.update!(data: Date.yesterday)

      expect { simular("simular_ok", "fastpass") }.not_to change(Acesso, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "informa quando não existe janela compatível sem criar outra" do
      janela_atual.update!(inicio: "13:00", fim: "13:15")

      expect { simular("simular_ok", "fastpass") }.not_to change(TimeFrame, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
