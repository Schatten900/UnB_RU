require "rails_helper"

RSpec.describe "API de recargas", type: :request do
  let(:usuario) do
    Usuario.create!(
      matricula: "221012345",
      nome: "Estudante",
      senha: "senha-segura",
      perfil: "estudante",
      saldo: 5
    )
  end

  it "recusa recarga sem sessao autenticada" do
    post api_recargas_path, params: { valor: "10.00", metodo: "pix" }

    expect(response).to have_http_status(:unauthorized)
  end

  it "confirma recarga PIX usando a rota e status definidos" do
    post login_path, params: { matricula: usuario.matricula, senha: "senha-segura" }
    post api_recargas_path, params: { valor: "10.00", metodo: "pix" }
    recarga_id = JSON.parse(response.body).fetch("recarga").fetch("id")

    post confirmar_api_recarga_path(recarga_id)

    expect(response).to have_http_status(:ok)
    expect(usuario.reload.saldo).to eq(BigDecimal("15.00"))
    expect(Recarga.find(recarga_id).status).to eq("concluida")
  end
end