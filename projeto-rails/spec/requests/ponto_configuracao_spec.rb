require "rails_helper"

RSpec.describe "Configuracao do ponto de acesso", type: :request do
  let(:turno) do
    Turno.create!(nome: "Expediente", inicio: "09:00", fim: "17:00", preco: 0)
  end

  let(:funcionario) do
    Usuario.create!(
      matricula: "999123456",
      nome: "Funcionario de teste",
      senha: "senha-segura",
      perfil: "funcionario",
      turno: turno,
      saldo: 0
    )
  end

  it "exige funcionario autenticado" do
    get operator_ponto_configuracao_path

    expect(response).to redirect_to(login_path)
  end

  it "salva restaurante e catraca na sessao" do
    restaurante = Restaurante.create!(nome: "RU de teste")
    catraca = restaurante.catracas.create!(piso: 1, modo_acesso: "normal")
    allow(Time).to receive(:current).and_return(Time.find_zone!("America/Sao_Paulo").local(2026, 10, 30, 12, 0))
    post login_path, params: { matricula: funcionario.matricula, senha: "senha-segura" }

    post operator_ponto_configuracao_path,
      params: { restaurante_id: restaurante.id, catraca_id: catraca.id }

    expect(response).to redirect_to(operator_ponto_configuracao_path)
    expect(session[:restaurante_id]).to eq(restaurante.id)
    expect(session[:catraca_id]).to eq(catraca.id)
  end

  it "rejeita catraca que nao pertence ao restaurante informado" do
    restaurante = Restaurante.create!(nome: "RU de teste")
    outro_restaurante = Restaurante.create!(nome: "Outro RU")
    catraca = outro_restaurante.catracas.create!(piso: 1, modo_acesso: "fastpass")
    allow(Time).to receive(:current).and_return(Time.find_zone!("America/Sao_Paulo").local(2026, 10, 30, 12, 0))
    post login_path, params: { matricula: funcionario.matricula, senha: "senha-segura" }

    post operator_ponto_configuracao_path,
      params: { restaurante_id: restaurante.id, catraca_id: catraca.id }

    expect(response).to have_http_status(:unprocessable_content)
    expect(session[:catraca_id]).to be_nil
  end
end
