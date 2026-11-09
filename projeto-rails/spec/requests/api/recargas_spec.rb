# spec/requests/api/recargas_spec.rb
require "rails_helper"

RSpec.describe "Api::Recargas", type: :request do
  let(:usuario) do
    Usuario.create!(
      matricula: "221012345", 
      nome: "Estudante",
      senha_hash: BCrypt::Password.create("12345678"), 
      perfil: "estudante", 
      saldo: 5
    )
  end

  def logar_usuario(user)
    post login_path, params: { matricula: user.matricula, senha: "12345678" } rescue nil
    if respond_to?(:session)
      session[:usuario_matricula] = user.matricula
    end
  end

  def deslogar_usuario
    delete logout_path rescue nil
    if respond_to?(:session)
      session[:usuario_matricula] = nil
    end
  end

  before { logar_usuario(usuario) }

  describe "POST /api/recargas" do
    context "método PIX" do
      it "cria recarga pendente e responde 201" do
        expect {
          post "/api/recargas",
               params: { valor: "30", metodo: "pix" }, as: :json
        }.to change(Recarga, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["mensagem"]).to eq("Recarga criada com sucesso")
        expect(json["recarga"]["metodo"]).to eq("pix")
        expect(json["recarga"]["status"]).to eq("pendente")
        expect(json["saldo"].to_f).to eq(5.0)
      end
    end

    context "método cartão de crédito" do
      it "cria recarga confirmada, incrementa saldo e responde 201" do
        expect {
          post "/api/recargas",
               params: { valor: "100", metodo: "cartao_credito" }, as: :json
        }.to change(Recarga, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["recarga"]["status"]).to eq("confirmada")
        expect(json["saldo"].to_f).to eq(105.0)
      end
    end

    context "parâmetros inválidos" do
      it "rejeita valor zero" do
        expect {
          post "/api/recargas",
               params: { valor: "0", metodo: "pix" }, as: :json
        }.not_to change(Recarga, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["erro"])
          .to eq("Por favor, insira um valor de crédito válido")
      end

      it "rejeita valor não numérico" do
        post "/api/recargas",
             params: { valor: "abc", metodo: "pix" }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejeita método desconhecido" do
        post "/api/recargas",
             params: { valor: "10", metodo: "boleto" }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "autenticação" do
      it "retorna 401 sem usuário logado" do
        deslogar_usuario
        post "/api/recargas",
             params: { valor: "10", metodo: "pix" }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/recargas/:id/confirmar" do
    def criar_recarga(status: "pendente", metodo: "pix")
      usuario.recargas.create!(
        valor: 50, metodo: metodo, status: status,
        data_hora: Time.current, codigo_pix: "PIX-TEST"
      )
    end

    it "confirma recarga pendente e incrementa saldo" do
      recarga = criar_recarga

      expect {
        post "/api/recargas/#{recarga.id}/confirmar"
      }.to change { usuario.reload.saldo }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["mensagem"]).to eq("Pagamento confirmado")
      expect(json["saldo"].to_f).to eq(55.0)
      expect(recarga.reload.status).to eq("confirmada")
    end

    it "não permite confirmar recarga já confirmada" do
      recarga = criar_recarga(status: "confirmada")

      expect {
        post "/api/recargas/#{recarga.id}/confirmar"
      }.not_to change { usuario.reload.saldo }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(recarga.reload.status).to eq("confirmada")
    end

    it "não permite confirmar recarga de outro usuário" do
      outro = Usuario.create!(
        matricula: "231045229", nome: "Outro",
        senha_hash: BCrypt::Password.create("s"), perfil: "estudante", saldo: 0
      )
      recarga = outro.recargas.create!(
        valor: 10, metodo: "pix", status: "pendente",
        data_hora: Time.current
      )

      expect {
        post "/api/recargas/#{recarga.id}/confirmar"
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

# NOTE: PLEASE DON'T REMOVE AI USE DISCLOSURE COMMENTS! 
# AI: Deepseek with think and search
# Strategy and prompt: The prompt was crafted by simply asking the AI, in natural language, to provide a Respec test, giving existing spec files to it
# AI: Gemini desktop
# Strategy and prompt: provided spec files, model and api files, and asked for the correction with authentication method