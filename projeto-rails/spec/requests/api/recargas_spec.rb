require "rails_helper"

RSpec.describe "Api::Recargas", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:usuario) do
    Usuario.create!(
      matricula: "221012345", nome: "Estudante",
      senha_hash: "senha-hash", perfil: "estudante", saldo: 0
    )
  end

  before { sign_in usuario }

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
        expect(json["recarga"]["codigo_pix"]).to match(/\APIX-MOCK-/)
        expect(json["saldo"].to_f).to eq(0.0)
      end
    end

    context "método cartão de crédito" do
      # BUG: serviço usa :confirmada (enum inválido). Este spec só
      # passará quando o serviço for corrigido para :concluida.
      it "cria recarga concluída, incrementa saldo e responde 201" do
        expect {
          post "/api/recargas",
               params: { valor: "100", metodo: "cartao_credito" }, as: :json
        }.to change(Recarga, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["recarga"]["status"]).to eq("concluida")
        expect(json["saldo"].to_f).to eq(100.0)
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
        sign_out usuario
        post "/api/recargas",
             params: { valor: "10", metodo: "pix" }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/recargas/:id/confirm" do
    def criar_recarga(status: "pendente", metodo: "pix")
      usuario.recargas.create!(
        valor: 50, metodo: metodo, status: status,
        data_hora: Time.current, codigo_pix: "PIX-TEST"
      )
    end

    it "confirma recarga pendente e incrementa saldo" do
      recarga = criar_recarga

      expect {
        post "/api/recargas/#{recarga.id}/confirm"
      }.to change { usuario.reload.saldo }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["mensagem"]).to eq("Pagamento confirmado")
      expect(json["saldo"].to_f).to eq(50.0)
      expect(recarga.reload.status).to eq("concluida")
    end

    it "não permite confirmar recarga já concluída" do
      recarga = criar_recarga(status: "concluida")

      expect {
        post "/api/recargas/#{recarga.id}/confirm"
      }.not_to change { usuario.reload.saldo }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["erro"])
        .to eq("Não foi possível confirmar o pagamento")
      expect(recarga.reload.status).to eq("concluida")
    end

    it "não permite confirmar recarga de outro usuário" do
      outro = Usuario.create!(
        matricula: "231045229", nome: "Outro",
        senha_hash: "s", perfil: "estudante", saldo: 0
      )
      recarga = outro.recargas.create!(
        valor: 10, metodo: "pix", status: "pendente",
        data_hora: Time.current
      )

      expect {
        post "/api/recargas/#{recarga.id}/confirm"
      }.to raise_error(ActiveRecord::RecordNotFound)

      expect(recarga.reload.status).to eq("pendente")
    end
  end
end