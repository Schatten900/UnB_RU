require "rails_helper"

RSpec.describe Recarga, type: :model do
  def criar_usuario(matricula: "221012345")
    Usuario.create!(
      matricula: matricula, nome: "Estudante #{matricula}",
      senha_hash: "senha-hash", perfil: "estudante", saldo: 0
    )
  end

  let(:usuario) { criar_usuario }

  def atributos(**overrides)
    {
      usuario: usuario, valor: 10, metodo: "pix",
      status: "pendente", data_hora: Time.current
    }.merge(overrides)
  end

  describe "associações" do
    it "pertence ao usuario via matrícula" do
      reflexao = Recarga.reflect_on_association(:usuario)
      expect(reflexao.macro).to eq(:belongs_to)
      expect(reflexao.foreign_key).to eq("usuario_matricula")
      expect(reflexao.options[:primary_key]).to eq(:matricula)
    end
  end

  describe "validações" do
    it "é válida com os dados padrão" do
      expect(Recarga.new(atributos)).to be_valid
    end

    it "rejeita valor zero" do
      recarga = Recarga.new(atributos(valor: 0))
      expect(recarga).not_to be_valid
      expect(recarga.errors[:valor]).to be_present
    end

    it "rejeita valor negativo" do
      expect(Recarga.new(atributos(valor: -1))).not_to be_valid
    end

    it "rejeita valor não numérico" do
      expect(Recarga.new(atributos(valor: "abc"))).not_to be_valid
    end

    it "rejeita metodo ausente" do
      expect(Recarga.new(atributos(metodo: nil))).not_to be_valid
    end
  end

  describe "enums" do
    it "mapeia os métodos" do
      expect(Recarga.new(metodo: "pix")).to be_pix
      expect(Recarga.new(metodo: "cartao_credito")).to be_cartao_credito
    end

    it "persiste 'PIX' no banco mas expõe 'pix'" do
      recarga = Recarga.create!(atributos(metodo: "pix"))
      raw = Recarga.connection.select_value(
        "SELECT metodo FROM recargas WHERE id = #{recarga.id}"
      )
      expect(raw).to eq("PIX")
      expect(recarga.reload.metodo).to eq("pix")
    end

    it "mapeia os status" do
      expect(Recarga.new(status: "pendente")).to be_pendente
      expect(Recarga.new(status: "concluida")).to be_concluida
      expect(Recarga.new(status: "falhou")).to be_falhou
    end

    it "rejeita status inválido" do
      expect { Recarga.new(status: "confirmada") }
        .to raise_error(ArgumentError)
    end
  end
end

# AI: Deepseek wit think and search
# Strategy and prompt: The prompt was crafted by simply asking the AI, in natural language, to provide a Respec test, giving existing spec files to it