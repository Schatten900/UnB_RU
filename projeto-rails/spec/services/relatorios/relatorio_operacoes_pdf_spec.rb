require "rails_helper"

RSpec.describe Relatorios::RelatorioOperacoesPdf do
  def criar_usuario(matricula: "221012345")
    Usuario.create!(
      matricula: matricula, nome: "Estudante",
      senha_hash: "senha-hash", perfil: "estudante", saldo: 0
    )
  end

  def criar_recarga(usuario)
    Recarga.create!(
      usuario: usuario, valor: 20, metodo: "pix",
      status: "pendente", data_hora: Time.current
    )
  end

  describe "saída do PDF" do
    it "retorna uma string binária começando com %PDF" do
      pdf = described_class.generate
      expect(pdf).to be_a(String)
      expect(pdf).to start_with("%PDF")
    end

    it "não quebra quando não há dados" do
      expect { described_class.generate }.not_to raise_error
    end

    it "não quebra quando há dados" do
      criar_recarga(criar_usuario)
      expect { described_class.generate }.not_to raise_error
    end
  end

  describe "conteúdo" do
    # Substitui Prawn::Document.new por um dublê que acumula as chamadas a .text
    let(:textos) { [] }
    let(:construindo) do
      double("Prawn::Document").tap do |d|
        allow(d).to receive(:text) { |*args, **_opts| textos << args.first }
        allow(d).to receive(:move_down)
      end
    end

    before do
      final = double("rendered_pdf", render: "%PDF-fake")
      permitido = construindo
      allow(Prawn::Document).to receive(:new) do |&bloco|
        bloco.call(permitido)
        final
      end
    end

    it "escreve os dados de cada recarga" do
      usuario = criar_usuario
      recarga = criar_recarga(usuario)

      described_class.generate

      expect(textos).to include("Relatório Global de Operações")
      expect(textos).to include("Recarga ##{recarga.id}")
      expect(textos).to include("Matrícula: #{usuario.matricula}")
      expect(textos).to include("Valor: R$ #{recarga.valor}")
      expect(textos).to include("Método: #{recarga.metodo}")
    end
  end
end
# AI: Deepseek wit think and search
# Strategy and prompt: The prompt was crafted by simply asking the AI, in natural language, to provide a Respec test, giving existing spec files to it