require "rails_helper"

RSpec.describe "Gestao de Restaurantes e Catracas (US13)", type: :request do
  let(:administrador) do
    Usuario.create!(matricula: "999900001", nome: "Administrador", senha: "Senha123!", saldo: 0)
  end
  let(:estudante) do
    Usuario.create!(matricula: "232040501", nome: "Estudante", senha: "Senha123!", saldo: 0)
  end
  let(:restaurante) { Restaurante.create!(nome: "RU Darcy Ribeiro") }
  let(:catraca) { restaurante.catracas.create!(piso: 2, modo_acesso: "normal") }

  def entrar(usuario = administrador)
    post login_path, params: { matricula: usuario.matricula, senha: "Senha123!" }
  end

  it "exige autenticacao administrativa" do
    get admin_restaurantes_path
    expect(response).to redirect_to(login_path)

    post admin_restaurantes_path, params: { restaurante: { nome: "RU indevido" } }
    expect(response).to redirect_to(login_path)
    expect(Restaurante.exists?(nome: "RU indevido")).to be(false)
  end

  it "nega acesso a estudantes" do
    entrar(estudante)

    get admin_restaurantes_path
    expect(response).to redirect_to(login_path)
  end

  it "impede que estudantes cadastrem catracas" do
    unidade = restaurante
    entrar(estudante)

    expect do
      post admin_catracas_path, params: {
        catraca: { restaurante_id: unidade.id, piso: 1, modo_acesso: "normal" }
      }
    end.not_to change(Catraca, :count)

    expect(response).to redirect_to(login_path)
  end

  it "exibe estado vazio para administrador sem unidades" do
    entrar

    get admin_restaurantes_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Gestão de Restaurantes e Catracas Físicas")
    expect(response.body).to include("Nenhuma unidade cadastrada")
  end

  it "lista restaurantes, catracas por piso e indicadores reais" do
    catraca
    restaurante.catracas.create!(piso: 1, modo_acesso: "fastpass")
    entrar

    get admin_restaurantes_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("RU Darcy Ribeiro", "PISO 1", "PISO 2")
    expect(response.body).to include("CATRACAS CADASTRADAS", "CATRACAS FASTPASS")
    expect(response.body).to include("Modo comum", "FastPass")
  end

  it "cadastra um restaurante usando o service" do
    entrar

    expect do
      post admin_restaurantes_path, params: { restaurante: { nome: "RU Gama" } }
    end.to change(Restaurante, :count).by(1)

    expect(response).to redirect_to(admin_restaurantes_path)
    expect(Restaurante.last.nome).to eq("RU Gama")
  end

  it "rejeita restaurante sem nome" do
    entrar

    expect do
      post admin_restaurantes_path, params: { restaurante: { nome: "" } }
    end.not_to change(Restaurante, :count)

    expect(response).to redirect_to(admin_restaurantes_path)
    follow_redirect!
    expect(response.body).to include("rg-notice-error")
  end

  it "edita o nome de um restaurante" do
    unidade = restaurante
    entrar

    patch admin_restaurante_path(unidade), params: { restaurante: { nome: "RU FCTE" } }

    expect(response).to redirect_to(admin_restaurantes_path)
    expect(unidade.reload.nome).to eq("RU FCTE")
  end

  it "cadastra uma catraca associada ao restaurante" do
    unidade = restaurante
    entrar

    expect do
      post admin_catracas_path, params: {
        catraca: { restaurante_id: unidade.id, piso: 3, modo_acesso: "fastpass" }
      }
    end.to change(Catraca, :count).by(1)

    expect(Catraca.last.restaurante).to eq(unidade)
    expect(Catraca.last.piso).to eq(3)
    expect(Catraca.last.modo_acesso).to eq("fastpass")
  end

  it "edita o piso e modo de uma catraca" do
    equipamento = catraca
    entrar

    patch admin_catraca_path(equipamento), params: {
      catraca: { piso: 1, modo_acesso: "fastpass" }
    }

    expect(response).to redirect_to(admin_restaurantes_path)
    expect(equipamento.reload.piso).to eq(1)
    expect(equipamento.modo_acesso).to eq("fastpass")
  end

  it "rejeita modo de acesso invalido" do
    equipamento = catraca
    entrar

    patch admin_catraca_path(equipamento), params: {
      catraca: { piso: 1, modo_acesso: "inexistente" }
    }

    expect(response).to redirect_to(admin_restaurantes_path)
    expect(equipamento.reload.modo_acesso).to eq("normal")
  end

  it "remove uma catraca sem acessos e depois o restaurante" do
    equipamento = catraca
    unidade = restaurante
    entrar

    expect { delete admin_catraca_path(equipamento) }.to change(Catraca, :count).by(-1)
    expect { delete admin_restaurante_path(unidade) }.to change(Restaurante, :count).by(-1)
  end

  it "impede remover restaurante que ainda possui catracas" do
    unidade = restaurante
    catraca
    entrar

    expect { delete admin_restaurante_path(unidade) }.not_to change(Restaurante, :count)
    expect(response).to redirect_to(admin_restaurantes_path)
    follow_redirect!
    expect(response.body).to include("Remova primeiro as catracas")
  end

  it "impede remover catraca que ja possui acessos associados" do
    equipamento = catraca
    usuario = estudante
    turno = Turno.create!(nome: "Almoço", inicio: "11:00", fim: "14:00", preco: "4.50")
    Acesso.create!(
      usuario: usuario, turno: turno, catraca: equipamento,
      data_hora: Time.current, status: "bloqueado", passagem_em: nil,
      valor_debitado: 0
    )
    entrar

    expect { delete admin_catraca_path(equipamento) }.not_to change(Catraca, :count)
    expect(response).to redirect_to(admin_restaurantes_path)
    follow_redirect!
    expect(response.body).to include("existem acessos associados")
  end

  it "mantem os dados disponiveis para a configuracao de ponto" do
    unidade = restaurante
    equipamento = catraca
    entrar

    get ponto_configuracao_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(unidade.nome)
    expect(response.body).to include("Catraca ##{equipamento.id}")
  end
end
