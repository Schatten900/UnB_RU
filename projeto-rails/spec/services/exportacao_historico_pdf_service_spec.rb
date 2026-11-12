require "rails_helper"

RSpec.describe ExportacaoHistoricoPdfService, type: :service do
  let(:estudante) { Usuario.create!(matricula: "221012345", nome: "Aluno João", senha: "senha", saldo: 20) }
  let(:outro) { Usuario.create!(matricula: "231045229", nome: "Outro", senha: "senha", saldo: 20) }
  let(:restaurante) { Restaurante.create!(nome: "RU Darcy") }
  let(:catraca) { Catraca.create!(restaurante: restaurante, piso: 1, modo_acesso: "normal") }
  let(:turno) { Turno.create!(nome: "Almoço", inicio: "11:00", fim: "14:00", preco: 4.50) }

  def recarga(usuario: estudante, data: "2026-05-02 12:00", status: "concluida", valor: 10)
    usuario.recargas.create!(data_hora: Time.find_zone!("America/Sao_Paulo").parse(data),
                            valor: valor, metodo: "pix", status: status)
  end

  def acesso(data: "2026-05-02 12:00", passagem: "2026-05-02 12:01", status: "liberado")
    zona = Time.find_zone!("America/Sao_Paulo")
    Acesso.create!(usuario: estudante, catraca: catraca, turno: turno,
                   data_hora: zona.parse(data), passagem_em: passagem && zona.parse(passagem),
                   status: status, valor_debitado: passagem ? 4.50 : 0)
  end

  def exportar(**opcoes)
    described_class.call(usuario: estudante, mes: 5, ano: 2026, **opcoes)
  end

  it "gera PDF real com todos os seis lançamentos de maio, sem abril ou outro estudante" do
    6.times { |i| recarga(valor: i + 1) }
    recarga(data: "2026-04-30 12:00", valor: 99)
    recarga(usuario: outro, valor: 88)
    resultado = exportar
    expect(resultado.tipo_mime).to eq("application/pdf")
    expect(resultado.conteudo).to start_with("%PDF-")
    expect(resultado.conteudo).to include("%%EOF")
    expect(resultado.nome_arquivo).to eq("historico_221012345.pdf")
    expect(resultado.lancamentos.size).to eq(6)
    expect(resultado.lancamentos.sum { |item| item[:valor] }).to eq(21)
  end

  it "gera PDF válido para um mês vazio" do
    resultado = exportar
    expect(resultado.lancamentos).to be_empty
    expect(resultado.conteudo).to start_with("%PDF-")
  end

  it "exporta somente recargas concluídas e refeições efetivamente consumidas" do
    recarga
    recarga(status: "pendente")
    acesso
    acesso(passagem: nil, status: "pendente")
    acesso(passagem: nil, status: "bloqueado")
    expect(exportar.lancamentos.map { |item| item[:tipo] }).to contain_exactly("recarga", "refeicao")
  end

  it "usa a data da passagem, inclusive na virada do mês no horário de Brasília" do
    acesso(data: "2026-04-30 23:59", passagem: "2026-05-01 00:01")
    acesso(data: "2026-05-31 23:59", passagem: "2026-06-01 00:01")
    recarga(data: "2026-04-30 23:59")
    recarga(data: "2026-05-31 23:59")
    expect(exportar.lancamentos.size).to eq(2)
    expect(exportar.lancamentos.count { |item| item[:tipo] == "refeicao" }).to eq(1)
  end

  it "aplica a interseção dos filtros de refeição, restaurante e método" do
    recarga
    confirmado = acesso
    outro_restaurante = Restaurante.create!(nome: "RU Gama")
    outra_catraca = Catraca.create!(restaurante: outro_restaurante, piso: 1, modo_acesso: "normal")
    acesso.update!(catraca: outra_catraca)
    outro_turno = Turno.create!(nome: "Jantar", inicio: "17:00", fim: "20:00", preco: 4.50)
    acesso.update!(turno: outro_turno)
    filtros = { evento: "turno:#{turno.id}", restaurante_id: restaurante.id.to_s, metodo: "comum" }
    expect(exportar(filtros: filtros).lancamentos.pluck(:id)).to eq(["acesso-#{confirmado.id}"])
    expect(exportar(filtros: filtros.merge(metodo: "fastpass")).lancamentos).to be_empty
  end

  it "aceita nomes com caracteres fora do alfabeto das fontes nativas" do
    estudante.update!(nome: "Aluno 🍽")
    expect(exportar.conteudo).to start_with("%PDF-")
  end

  it "recusa mês inválido e usuário ausente" do
    expect { described_class.call(usuario: estudante, filtros: { mes_referencia: "2026-13" }) }.to raise_error(ArgumentError)
    expect { described_class.call(usuario: nil, mes: 5, ano: 2026) }.to raise_error(ArgumentError)
  end
end
