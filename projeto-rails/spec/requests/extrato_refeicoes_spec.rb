require "rails_helper"

RSpec.describe "Extrato e histórico de refeições", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:zona) { Time.find_zone!("America/Sao_Paulo") }
  let(:estudante) { Usuario.create!(matricula: "232040501", nome: "Estudante do extrato", senha: "senha-segura", saldo: 18) }
  let(:outro) { Usuario.create!(matricula: "231045229", nome: "Outra pessoa", senha: "senha-segura", saldo: 0) }
  let(:turno) { Turno.create!(nome: "Almoço", inicio: "11:00", fim: "14:00", preco: 4.50) }
  let(:restaurante) { Restaurante.create!(nome: "RU Darcy Ribeiro") }
  let(:catraca) { restaurante.catracas.create!(piso: 1, modo_acesso: "normal") }

  around do |exemplo|
    travel_to(zona.local(2026, 5, 15, 12)) { exemplo.run }
  end

  before do
    post login_path, params: { matricula: estudante.matricula, senha: "senha-segura" }
  end

  def acesso(usuario: estudante, instante: Time.current, passagem: instante, ponto: catraca, status: "liberado")
    Acesso.create!(usuario: usuario, turno: turno, catraca: ponto,
                   data_hora: instante, passagem_em: passagem, status: status,
                   valor_debitado: passagem ? 4.50 : 0)
  end

  def recarga(usuario: estudante, valor: 45, status: :concluida, instante: Time.current, metodo: :pix)
    Recarga.create!(usuario: usuario, valor: valor, status: status, data_hora: instante, metodo: metodo)
  end

  def documento
    Nokogiri::HTML(response.body)
  end

  it "exibe somente refeições confirmadas e recargas concluídas da própria conta" do
    acesso
    acesso(passagem: nil, status: "pendente")
    acesso(passagem: nil, status: "bloqueado")
    recarga
    recarga(valor: 99, status: :pendente)
    recarga(valor: 98, status: :falhou)
    recarga(usuario: outro, valor: 777)

    get student_extrato_refeicoes_path

    expect(response).to have_http_status(:ok)
    expect(documento.css(".statement-table tbody tr").size).to eq(2)
    expect(documento.at_css(".statement-metrics").text).to include("R$ 4,50", "R$ 45,00", "1 refeições", "R$ 18,00")
    expect(response.body).not_to include("777,00", "99,00", "98,00", "Outra pessoa")
  end

  it "utiliza a confirmação da passagem para filtrar, contabilizar e exibir a refeição" do
    acesso(instante: zona.local(2026, 4, 30, 23, 59), passagem: zona.local(2026, 5, 1, 0, 1))

    get student_extrato_refeicoes_path, params: { periodo: "mes" }

    expect(response).to have_http_status(:ok)
    expect(documento.at_css(".statement-table tbody").text).to include("01/05/2026, 00:01")
    expect(documento.at_css(".statement-metrics").text).to include("R$ 4,50")
  end

  it "aplica período de 30 dias no horário de Brasília" do
    recarga(valor: 16, instante: zona.local(2026, 4, 16, 0, 0))
    recarga(valor: 15, instante: zona.local(2026, 4, 15, 23, 59))

    get student_extrato_refeicoes_path, params: { periodo: "30" }

    tabela = documento.at_css(".statement-table tbody").text
    expect(tabela).to include("16,00")
    expect(tabela).not_to include("15,00")
  end

  it "combina restaurante, turno e forma de acesso, excluindo recargas nesse filtro" do
    acesso
    outra_unidade = Restaurante.create!(nome: "RU Gama")
    outro_ponto = outra_unidade.catracas.create!(piso: 2, modo_acesso: "normal")
    acesso(ponto: outro_ponto)
    recarga

    get student_extrato_refeicoes_path, params: {
      periodo: "todos", restaurante_id: restaurante.id, evento: "turno:#{turno.id}", metodo: "comum"
    }

    expect(documento.css(".statement-table tbody tr").size).to eq(1)
    expect(documento.at_css(".statement-table tbody").text).to include("RU Darcy Ribeiro")
    expect(documento.at_css(".statement-table tbody").text).not_to include("RU Gama", "Recarga de Saldo")
  end

  it "filtra recargas pelo método de pagamento" do
    acesso
    recarga(valor: 20, metodo: :pix)
    recarga(valor: 30, metodo: :cartao_credito)

    get student_extrato_refeicoes_path, params: { evento: "recarga", metodo: "pix" }

    expect(documento.css(".statement-table tbody tr").size).to eq(1)
    expect(documento.at_css(".statement-table tbody").text).to include("20,00")
    expect(documento.at_css(".statement-table tbody").text).not_to include("30,00", "Almoço")
  end

  it "oferece somente Café da Manhã, Almoço e Jantar no filtro de refeição" do
    get student_extrato_refeicoes_path

    opcoes = documento.css("select#evento option").reject { |opcao| opcao["value"].blank? }
    expect(opcoes.map(&:text)).to eq(["Café da Manhã", "Almoço", "Jantar"])
    expect(documento.at_css("label[for='evento']").text).to eq("Refeição")
    expect(documento.css(".statement-table th").map(&:text)).to include("Refeição")
  end

  it "mantém filtros na paginação e mostra o estado vazio" do
    6.times { |indice| acesso(instante: Time.current - indice.minutes) }
    get student_extrato_refeicoes_path, params: { metodo: "comum", por_pagina: 5, pagina: 2 }

    expect(documento.css(".statement-table tbody tr").size).to eq(1)
    links = documento.css(".statement-pagination nav a").map { |link| link["href"] }
    expect(links.any? { |url| url.include?("metodo=comum") }).to be(true)

    get student_extrato_refeicoes_path, params: { metodo: "fastpass" }
    expect(response.body).to include("Nenhum lançamento encontrado")
  end

  it "exporta PDF real com todos os resultados filtrados, independentemente da página" do
    6.times { |indice| recarga(valor: indice + 1) }
    recarga(status: :pendente, valor: 99)
    recarga(usuario: outro, valor: 777)
    acesso

    expect(GeradorPdfHistorico).to receive(:call).with(
      usuario: estudante,
      lancamentos: satisfy { |itens| itens.size == 6 && itens.all? { |item| item[:tipo] == "recarga" } }
    ).and_call_original

    get student_exportar_extrato_refeicoes_path, params: {
      evento: "recarga", metodo: "pix", por_pagina: 5, pagina: 2
    }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/pdf")
    expect(response.body).to start_with("%PDF-")
    expect(response.headers["Content-Disposition"]).to include("attachment", estudante.matricula)
  end

  it "exporta um PDF válido mesmo sem lançamentos" do
    get student_exportar_extrato_refeicoes_path

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/pdf")
    expect(response.body).to start_with("%PDF-")
  end

  it "informa filtros inválidos e permite voltar ao extrato" do
    get student_extrato_refeicoes_path, params: { metodo: "boleto" }

    expect(response).to redirect_to(student_extrato_refeicoes_path)
    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Selecione um método válido.")
  end

  it "exibe comprovantes das próprias refeições e recargas concluídas" do
    refeicao = acesso
    credito = recarga

    [["refeicao", refeicao.id], ["recarga", credito.id]].each do |tipo, id|
      get student_recibo_extrato_refeicoes_path(tipo: tipo, id: id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Comprovante de lançamento", estudante.matricula)
      expect(documento.at_css(".main-nav [aria-current='page']")["href"]).to eq(student_extrato_refeicoes_path)
    end
  end

  it "permite baixar o comprovante em PDF" do
    refeicao = acesso
    get student_recibo_extrato_refeicoes_path(tipo: "refeicao", id: refeicao.id, format: :pdf)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/pdf")
    expect(response.body).to start_with("%PDF-")
  end

  it "não disponibiliza comprovantes de outra pessoa ou de operações não concluídas" do
    registros = [
      ["refeicao", acesso(usuario: outro).id],
      ["recarga", recarga(usuario: outro).id],
      ["refeicao", acesso(passagem: nil, status: "pendente").id],
      ["recarga", recarga(status: :pendente).id]
    ]

    registros.each do |tipo, id|
      get student_recibo_extrato_refeicoes_path(tipo: tipo, id: id)
      expect(response).to have_http_status(:not_found)
    end
  end

  it "exige autenticação em todas as operações" do
    refeicao = acesso
    delete logout_path

    [student_extrato_refeicoes_path, student_exportar_extrato_refeicoes_path,
     student_recibo_extrato_refeicoes_path(tipo: "refeicao", id: refeicao.id)].each do |url|
      get url
      expect(response).to redirect_to(login_path)
    end
  end

  it "nega acesso ao fluxo de extrato para operadores" do
    delete logout_path
    funcionario = Usuario.create!(matricula: "999123456", nome: "Fiscal", senha: "senha-segura", saldo: 0, turno: turno)
    post login_path, params: { matricula: funcionario.matricula, senha: "senha-segura" }

    get student_extrato_refeicoes_path

    expect(response).to redirect_to(login_path)
  end
end
