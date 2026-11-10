require "rails_helper"

RSpec.describe Recargas::CriarRecarga do
  let(:usuario) do
    Usuario.create!(
      matricula: "221012345", nome: "Estudante",
      senha_hash: "senha-hash", perfil: "estudante", saldo: 0
    )
  end

  describe "validações de entrada" do
    it "rejeita valor zero" do
      expect { described_class.new(usuario, "0", "pix").call }
        .to raise_error(ArgumentError)
    end

    it "rejeita valor negativo" do
      expect { described_class.new(usuario, "-5", "pix").call }
        .to raise_error(ArgumentError)
    end

    it "rejeita valor não numérico" do
      expect { described_class.new(usuario, "abc", "pix").call }
        .to raise_error(ArgumentError)
    end

    it "rejeita método desconhecido" do
      expect { described_class.new(usuario, "10", "boleto").call }
        .to raise_error(ArgumentError)
    end

    it "rejeita método nil" do
      expect { described_class.new(usuario, "10", nil).call }
        .to raise_error(ArgumentError)
    end

    it "aceita valor como string numérica" do
      recarga = described_class.new(usuario, "30.50", "pix").call
      expect(recarga.valor).to eq(30.50.to_d)
    end
  end

  describe "método PIX" do
    it "cria recarga pendente com código PIX" do
      expect {
        @recarga = described_class.new(usuario, "50", "pix").call
      }.to change(Recarga, :count).by(1)

      expect(@recarga.status).to eq("pendente")
      expect(@recarga.metodo).to eq("pix")
      expect(@recarga.codigo_pix).to match(/\APIX-MOCK-\d+-[0-9a-f]{8}\z/)
    end

    it "não incrementa o saldo do usuário" do
      expect {
        described_class.new(usuario, "50", "pix").call
      }.not_to change { usuario.reload.saldo }
    end
  end

  describe "método cartão de crédito" do
    # BUG: o serviço usa :confirmada, mas o enum só aceita pendente/concluida/falhou.
    # Este spec só passará quando o serviço for corrigido para :concluida.
    it "cria recarga concluída e incrementa o saldo" do
      expect {
        @recarga = described_class.new(usuario, "100", "cartao_credito").call
      }.to change(Recarga, :count).by(1)

      expect(@recarga.status).to eq("concluida")
      expect(@recarga.metodo).to eq("cartao_credito")
      expect(usuario.reload.saldo).to eq(100.to_d)
    end
  end

  describe "consistência transacional" do
    it "não deixa registros parciais se algo falhar no meio" do
      # força uma falha depois do create!, dentro do with_lock
      allow_any_instance_of(Recarga).to receive(:update!).and_raise(StandardError)
      expect {
        described_class.new(usuario, "50", "pix").call
      }.to raise_error(StandardError)
      expect(Recarga.count).to eq(0)
    end
  end
end
# AI: Deepseek wit think and search
# Strategy and prompt: The prompt was crafted by simply asking the AI, in natural language, to provide a Respec test, giving existing spec files to it