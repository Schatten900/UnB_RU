require "rails_helper"

RSpec.describe ExportacaoHistoricoPdfService, type: :service do
  let(:usuarios) do
    Class.new(ApplicationRecord) do
      self.table_name = "usuarios"
      self.primary_key = "matricula"
    end
  end
  let(:restaurantes) { Class.new(ApplicationRecord) { self.table_name = "restaurantes" } }
  let(:catracas) { Class.new(ApplicationRecord) { self.table_name = "catracas" } }
  let(:turnos) { Class.new(ApplicationRecord) { self.table_name = "turnos" } }
  let(:recargas) { Class.new(ApplicationRecord) { self.table_name = "recargas" } }
  let(:acessos) { Class.new(ApplicationRecord) { self.table_name = "acessos" } }

  let(:estudante) { criar_estudante("221012345") }
  let(:outro_estudante) { criar_estudante("231045229") }
  let(:restaurante) { restaurantes.create!(nome: "RU de teste") }
  let(:catraca) { catracas.create!(restaurante_id: restaurante.id, piso: 1, modo_acesso: "normal") }
  let(:turno) { turnos.create!(nome: "Almoco", inicio: "11:00", fim: "14:00", preco: 4.50) }

  def criar_estudante(matricula)
    usuarios.create!(matricula: matricula, nome: "Aluno #{matricula}",
                     senha_hash: "hash-#{matricula}", perfil: "estudante", saldo: 0)
  end

  def criar_recarga(usuario:, data_hora:, valor:)
    recargas.create!(usuario_matricula: usuario.matricula,
                     data_hora: Time.zone.parse(data_hora),
                     valor: valor, metodo: "PIX", status: "concluida")
  end

  def criar_acesso(usuario:, data_hora:, passagem_em: data_hora, status: "liberado")
    confirmacao = passagem_em && Time.zone.parse(passagem_em)
    acessos.create!(
      usuario_matricula: usuario.matricula,
      catraca_id: catraca.id, turno_id: turno.id,
      data_hora: Time.zone.parse(data_hora),
      status: status, passagem_em: confirmacao,
      valor_debitado: confirmacao ? 4.50 : 0
    )
  end

  def exportar(usuario: estudante, gerador_pdf: GeradorPdfHistoricoMock)
    described_class.call(
      usuario: usuario, mes: 5, ano: 2026,
      recargas_model: recargas, acessos_model: acessos,
      gerador_pdf: gerador_pdf
    )
  end

  it "inclui lancamentos de todas as paginas do mes selecionado" do
    6.times do |i|
      criar_recarga(usuario: estudante,
                    data_hora: format("2026-05-%02d 12:00", i + 1), valor: i + 1)
    end
    criar_recarga(usuario: estudante, data_hora: "2026-04-30 12:00", valor: 99)

    resultado = exportar
    expect(resultado.simulado).to be(true)
    expect(resultado.lancamentos.size).to eq(6)
    expect(resultado.lancamentos.map { |item| item[:valor] }).not_to include(99.to_d)
  end

  it "permite exportar mes vazio" do
    resultado = exportar
    expect(resultado.lancamentos).to be_empty
    expect(resultado.conteudo).to include("Total de lancamentos: 0")
    expect(resultado.tipo_mime).to eq("text/plain")
  end

  it "exclui recargas pendentes e falhas da exportação mensal" do
    criar_recarga(usuario: estudante, data_hora: "2026-05-01 09:00", valor: 20)
    pendente = criar_recarga(usuario: estudante, data_hora: "2026-05-02 09:00", valor: 99)
    pendente.update!(status: "pendente")
    falha = criar_recarga(usuario: estudante, data_hora: "2026-05-03 09:00", valor: 98)
    falha.update!(status: "falhou")

    expect(exportar.lancamentos.map { |item| item[:valor] }).to eq([20.to_d])
  end

  it "nao inclui dados de outro estudante" do
    criar_recarga(usuario: estudante, data_hora: "2026-05-02 12:00", valor: 10)
    criar_recarga(usuario: outro_estudante, data_hora: "2026-05-03 12:00", valor: 20)

    expect(exportar.lancamentos.map { |item| item[:valor] }).to eq([10.to_d])
  end

  it "inclui recargas e passagens efetivamente confirmadas" do
    criar_recarga(usuario: estudante, data_hora: "2026-05-01 09:00", valor: 20)
    criar_acesso(usuario: estudante, data_hora: "2026-05-01 12:00")
    criar_acesso(usuario: estudante, data_hora: "2026-05-02 12:00")

    resultado = exportar
    expect(resultado.lancamentos.map { |item| item[:tipo] }).to eq(%w[recarga acesso acesso])
    expect(resultado.lancamentos.map { |item| item[:valor] }).to eq([20.to_d, 4.5.to_d, 4.5.to_d])
    expect(resultado.lancamentos.last[:status]).to eq("liberado")
  end

  it "exclui tentativas bloqueadas e pendentes do historico de refeicoes" do
    criar_acesso(usuario: estudante, data_hora: "2026-05-02 12:00",
                passagem_em: nil, status: "bloqueado")
    criar_acesso(usuario: estudante, data_hora: "2026-05-03 12:00",
                passagem_em: nil, status: "pendente")
    criar_acesso(usuario: estudante, data_hora: "2026-05-04 12:00")

    expect(Acesso.count).to eq(3)
    expect(exportar.lancamentos.map { |item| item[:tipo] }).to eq(["acesso"])
  end

  it "filtra pela data de passagem, nao pela data da tentativa" do
    criar_acesso(usuario: estudante, data_hora: "2026-04-30 23:59",
                passagem_em: "2026-05-01 00:01")
    criar_acesso(usuario: estudante, data_hora: "2026-05-31 23:59",
                passagem_em: "2026-06-01 00:01")

    registros = exportar.lancamentos
    expect(registros.size).to eq(1)
    expect(registros.first[:data_hora]).to eq(Time.zone.parse("2026-05-01 00:01"))
  end

  it "delega a geracao do documento ao mock substituivel" do
    criar_recarga(usuario: estudante, data_hora: "2026-05-10 12:00", valor: 15)
    gerador = class_double(GeradorPdfHistoricoMock)

    expect(gerador).to receive(:call).with(
      usuario: estudante,
      lancamentos: array_including(hash_including(tipo: "recarga", valor: 15.to_d))
    ).and_return(:resultado_do_gerador)

    expect(exportar(gerador_pdf: gerador)).to eq(:resultado_do_gerador)
  end
end

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
