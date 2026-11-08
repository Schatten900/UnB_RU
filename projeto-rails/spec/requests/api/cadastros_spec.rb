require "rails_helper"

RSpec.describe "API de cadastro", type: :request do
  it "salva senha com BCrypt e autentica a sessao criada" do
    post api_cadastro_path, params: {
      matricula: "231034304",
      nome: "Novo estudante",
      senha: "senha-segura"
    }

    usuario = Usuario.find("231034304")
    expect(response).to have_http_status(:created)
    expect(usuario.senha_hash).not_to eq("senha-segura")
    expect(usuario.senha_correta?("senha-segura")).to be(true)

    post api_recargas_path, params: { valor: "10.00", metodo: "pix" }

    expect(response).to have_http_status(:created)
  end
end