require "rails_helper"

RSpec.describe TimeFrame, type: :model do
  let(:turno) do
    Turno.create!(nome: "Almoço", inicio: "11:00", fim: "14:30", preco: 4.5)
  end

  def atributos(**overrides)
    { turno: turno, inicio: "11:00", fim: "11:30" }.merge(overrides)
  end

  it "é válido com dados padrão" do
    expect(TimeFrame.new(atributos)).to be_valid
  end

  it "exige turno" do
    expect(TimeFrame.new(atributos(turno: nil))).not_to be_valid
  end

  it "exige inicio" do
    expect(TimeFrame.new(atributos(inicio: nil))).not_to be_valid
  end

  it "exige fim" do
    expect(TimeFrame.new(atributos(fim: nil))).not_to be_valid
  end

  it "rejeita fim igual ao início" do
    tf = TimeFrame.new(atributos(inicio: "11:00", fim: "11:00"))
    expect(tf).not_to be_valid
    expect(tf.errors[:fim]).to include("deve ser posterior ao início")
  end

  it "rejeita fim anterior ao início" do
    tf = TimeFrame.new(atributos(inicio: "11:30", fim: "11:00"))
    expect(tf).not_to be_valid
    expect(tf.errors[:fim]).to include("deve ser posterior ao início")
  end

  it "não valida a regra quando inicio ou fim estão em branco" do
    tf = TimeFrame.new(atributos(inicio: nil))
    tf.valid?
    expect(tf.errors[:fim]).not_to include("deve ser posterior ao início")
  end
end
# AI: Deepseek wit think and search
# Strategy and prompt: The prompt was crafted by simply asking the AI, in natural language, to provide a Respec test, giving existing spec files to it