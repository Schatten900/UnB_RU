require "rails_helper"

RSpec.describe Turno, type: :model do
  def atributos(**overrides)
    { nome: "Almoço", inicio: "11:00", fim: "14:30", preco: 4.5 }.merge(overrides)
  end

  describe "validações" do
    it "é válido com dados padrão" do
      expect(Turno.new(atributos)).to be_valid
    end

    it "exige nome" do
      expect(Turno.new(atributos(nome: nil))).not_to be_valid
    end

    it "exige inicio" do
      expect(Turno.new(atributos(inicio: nil))).not_to be_valid
    end

    it "exige fim" do
      expect(Turno.new(atributos(fim: nil))).not_to be_valid
    end

    it "rejeita preço negativo" do
      expect(Turno.new(atributos(preco: -0.01))).not_to be_valid
    end

    it "aceita preço zero" do
      expect(Turno.new(atributos(preco: 0))).to be_valid
    end

    it "rejeita fim igual ao início" do
      turno = Turno.new(atributos(inicio: "11:00", fim: "11:00"))
      expect(turno).not_to be_valid
      expect(turno.errors[:fim]).to include("deve ser posterior ao início")
    end

    it "rejeita fim anterior ao início" do
      turno = Turno.new(atributos(inicio: "14:00", fim: "11:00"))
      expect(turno).not_to be_valid
    end
  end

  describe "associações" do
    it "possui muitos time_frames dependentes" do
      reflexao = Turno.reflect_on_association(:time_frames)
      expect(reflexao.macro).to eq(:has_many)
      expect(reflexao.options[:dependent]).to eq(:destroy)
    end

    it "possui muitos acessos" do
      expect(Turno.reflect_on_association(:acessos).macro).to eq(:has_many)
    end

    it "destrói time_frames ao ser removido" do
      turno = Turno.create!(atributos)
      turno.time_frames.create!(inicio: "11:00", fim: "11:30")
      expect { turno.destroy }.to change(TimeFrame, :count).by(-1)
    end
  end
end
# AI: Deepseek wit think and search
# Strategy and prompt: The prompt was crafted by simply asking the AI, in natural language, to provide a Respec test, giving existing spec files to it