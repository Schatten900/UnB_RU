# spec/requests/api/cadastros_spec.rb
require "rails_helper"

RSpec.describe "Cadastro de estudante", type: :request do
  let(:url) { "/api/cadastros" }
  let(:valid_params) do
    {
      matricula: "221012345",
      nome: "Maria Silva",
      senha: "senha-segura"
    }
  end

  describe "POST /api/cadastros" do
    context "com dados válidos" do
      it "cria um estudante e retorna 201 com os dados públicos" do
        expect {
          post url, params: valid_params, as: :json
        }.to change(Usuario, :count).by(1)

        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json["mensagem"]).to eq("Conta criada com sucesso")
        expect(json["usuario"]).to include(
          "matricula" => "221012345",
          "nome"      => "Maria Silva",
          "perfil"    => "estudante"
        )
        expect(json["usuario"]["saldo"].to_f).to eq(0.0)
      end

      it "persiste o usuário com perfil estudante, saldo zero e senha com hash seguro (BCrypt)" do
        post url, params: valid_params, as: :json

        usuario = Usuario.find_by(matricula: "221012345")
        expect(usuario).to be_present
        expect(usuario.nome).to eq("Maria Silva")
        expect(usuario.senha_hash).to be_present
        expect(usuario.senha_hash).not_to eq("senha-segura") # Garante que foi criptografado com BCrypt
        expect(usuario.perfil).to eq("estudante")
        expect(usuario.saldo).to eq(0)
      end

      it "ignora perfil e saldo enviados nos parâmetros" do
        post url, params: valid_params.merge(perfil: "admin", saldo: 9_999), as: :json

        usuario = Usuario.find_by(matricula: "221012345")
        expect(usuario.perfil).to eq("estudante")
        expect(usuario.saldo).to eq(0)
        expect(response).to have_http_status(:created)
      end
    end

    context "com matrícula inválida" do
      shared_examples "matrícula rejeitada" do |matricula|
        it "rejeita #{matricula.inspect} sem criar usuário" do
          expect {
            post url, params: valid_params.merge(matricula: matricula), as: :json
          }.not_to change(Usuario, :count)

          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)["erro"]).to eq(
            "Você deve fornecer um número de estudante válido"
          )
        end
      end

      include_examples "matrícula rejeitada", ""            # vazia
      include_examples "matrícula rejeitada", "12345678"     # 8 dígitos
      include_examples "matrícula rejeitada", "2210123456"   # 10 dígitos
      include_examples "matrícula rejeitada", "22101A345"    # contém letra
      include_examples "matrícula rejeitada", "22101 2345"    # contém espaço
      include_examples "matrícula rejeitada", "999123456"    # começa com 999
      include_examples "matrícula rejeitada", "999999999"    # começa com 999

      it "trata matrícula ausente como inválida" do
        post url, params: valid_params.except(:matricula), as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["erro"]).to eq(
          "Você deve fornecer um número de estudante válido"
        )
      end
    end

    context "quando o modelo não consegue salvar" do
      it "retorna os erros de validação do modelo com status 422" do
        erros = ActiveModel::Errors.new(Usuario.new)
        erros.add(:base, "Erro simulado")
        usuario_double = instance_double(Usuario, save: false, errors: erros)
        allow(Usuario).to receive(:new).and_return(usuario_double)

        post url, params: valid_params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["erros"]).to eq(["Erro simulado"])
      end

      it "rejeita matrícula duplicada (se houver validação de unicidade)" do
        Usuario.create!(
          matricula: "221012345",
          nome: "Outra Pessoa",
          senha_hash: BCrypt::Password.create("outra-senha"),
          perfil: "estudante",
          saldo: 0
        )

        expect {
          post url, params: valid_params, as: :json
        }.not_to change(Usuario, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["erros"]).to be_present
      end
    end
  end
end
# AI: Gemini
# Strategy and prompt: The prompt was crafted by simply asking the AI, in natural language, alongside conflicting github file, assitence with merging both tests
# AI: Deepseek with think and search
# Strategy and prompt: The prompt was crafted by simply asking the AI, in natural language, to provide a Respec test, giving existing spec files to it