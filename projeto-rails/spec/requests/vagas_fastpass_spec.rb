require "rails_helper"

RSpec.describe "Configuração de cotas FastPass", type: :request do
  let(:admin) { Usuario.create!(matricula: "999900001", nome: "Admin", perfil: "administrador", senha: "senha-segura", saldo: 0) }
  let!(:restaurante) { Restaurante.create!(nome: "RU") }
  let!(:turno) { Turno.create!(nome: "Almoço", inicio: "11:00", fim: "14:00", preco: 4.5) }
  let!(:janela) { turno.time_frames.create!(inicio: "11:00", fim: "11:15") }
  let!(:outra) { turno.time_frames.create!(inicio: "11:15", fim: "11:30") }
  let(:dados) { { restaurante_id: restaurante.id, data: Date.current.to_s, cota_diaria: "7", cotas: { janela.id.to_s => "4", outra.id.to_s => "3" } } }

  before { post login_path, params: { matricula: admin.matricula, senha: "senha-segura" } }

  it "mostra janelas reais e o campo diário sem indicadores ilustrativos" do
    get admin_vagas_fastpass_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('name="cota_diaria"', 'name="cotas[' + janela.id.to_s + ']"')
    expect(response.body).not_to include("Taxa Média de Ocupação", "Capacidade Segura", "ilustrativas")
  end

  it "salva as cotas por restaurante e sorteio e recarrega os valores" do
    post admin_vagas_fastpass_path, params: dados
    expect(Sorteio.last.cotas.fetch(restaurante.id.to_s)).to eq(janela.id.to_s => 4, outra.id.to_s => 3)
    expect(Sorteio.last.cotas_do_restaurante(restaurante).values.sum).to eq(7)
    follow_redirect!
    expect(response.body).to include('value="7"')
  end

  it "rejeita soma diferente sem sobrescrever cotas salvas" do
    post admin_vagas_fastpass_path, params: dados
    post admin_vagas_fastpass_path, params: dados.merge(cota_diaria: "8")
    expect(Sorteio.last.cotas_do_restaurante(restaurante).values.sum).to eq(7)
    expect(flash[:alert]).to include("soma")
  end

  it "substitui as cotas do restaurante selecionado preservando os outros restaurantes" do
    outro = Restaurante.create!(nome: "Outro RU")
    post admin_vagas_fastpass_path, params: dados.merge(restaurante_id: outro.id)
    post admin_vagas_fastpass_path, params: dados
    post admin_vagas_fastpass_path, params: dados.merge(cotas: { janela.id.to_s => "2", outra.id.to_s => "5" })

    sorteio = Sorteio.find_by!(data: Date.current)
    expect(sorteio.cotas.fetch(restaurante.id.to_s)).to eq(janela.id.to_s => 2, outra.id.to_s => 5)
    expect(sorteio.cotas.fetch(outro.id.to_s)).to eq(janela.id.to_s => 4, outra.id.to_s => 3)
    expect(Sorteio.count).to eq(1)
  end

  it "desconsidera cotas de janelas removidas ao reabrir a grade" do
    post admin_vagas_fastpass_path, params: dados
    janela.destroy!
    get admin_vagas_fastpass_path, params: { restaurante_id: restaurante.id, data: Date.current.to_s }
    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML(response.body).at_css('input[name="cota_diaria"]')["value"]).to eq("3")
  end

  it "rejeita valores negativos, janelas ausentes e sorteios fechados" do
    post admin_vagas_fastpass_path, params: dados.merge(cotas: { janela.id.to_s => "-1" })
    expect(Sorteio.all.all? { |sorteio| sorteio.cotas.empty? }).to be(true)
    post admin_vagas_fastpass_path, params: dados.merge(cotas: { janela.id.to_s => "7" })
    expect(Sorteio.all.all? { |sorteio| sorteio.cotas.empty? }).to be(true)
    Sorteio.create!(data: Date.current, status: "fechado")
    post admin_vagas_fastpass_path, params: dados
    expect(Sorteio.all.all? { |sorteio| sorteio.cotas.empty? }).to be(true)
    expect(flash[:alert]).to include("abertos")
  end

  it "impede visitantes de aplicar cotas" do
    delete logout_path
    post admin_vagas_fastpass_path, params: dados
    expect(response).to redirect_to(login_path)
    expect(Sorteio.all.all? { |sorteio| sorteio.cotas.empty? }).to be(true)
  end
end
