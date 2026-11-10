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
    expect(response.body).to include('aria-current="page"', "Nenhuma cobrança é realizada", "Aguardando identificação")

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
end
