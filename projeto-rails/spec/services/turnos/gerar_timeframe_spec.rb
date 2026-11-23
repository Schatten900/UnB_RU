require "rails_helper"

RSpec.describe Turnos::GerarTimeframe do
  let(:turno) do
    Turno.create!(nome: "Almoço", inicio: "11:00", fim: "12:00", preco: 4.5)
  end

  it "divide um turno de 1h em 2 timeframes de 30min" do
    described_class.new(turno, 30).call
    frames = turno.time_frames.reload.order(:inicio)

    expect(frames.size).to eq(2)
    expect(frames.map { |f| f.inicio.strftime("%H:%M") })
      .to eq(["11:00", "11:30"])
    expect(frames.map { |f| f.fim.strftime("%H:%M") })
      .to eq(["11:30", "12:00"])
  end

  it "ajusta o último frame para não ultrapassar o fim do turno" do
    described_class.new(turno, 25).call
    frames = turno.time_frames.reload.order(:inicio)

    expect(frames.size).to eq(3)
    expect(frames.last.fim.strftime("%H:%M")).to eq("12:00")
  end

  it "aceita duração como string" do
    described_class.new(turno, "30").call
    expect(turno.time_frames.reload.count).to eq(2)
  end

  it "apaga timeframes antigos antes de regerar" do
    turno.time_frames.create!(inicio: "11:00", fim: "11:10")
    described_class.new(turno, 30).call
    expect(turno.time_frames.reload.count).to eq(2)
  end

  it "rejeita duração zero" do
    expect { described_class.new(turno, 0).call }
      .to raise_error(ArgumentError)
  end

  it "rejeita duração negativa" do
    expect { described_class.new(turno, -5).call }
      .to raise_error(ArgumentError)
  end

  it "rejeita duração não numérica" do
    expect { described_class.new(turno, "abc").call }
      .to raise_error(ArgumentError)
  end
end
# AI: Deepseek wit think and search
# Strategy and prompt: The prompt was crafted by simply asking the AI, in natural language, to provide a Respec test, giving existing spec files to it