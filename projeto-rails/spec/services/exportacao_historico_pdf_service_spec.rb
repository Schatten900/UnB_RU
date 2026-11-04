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
  let(:catraca) do
    catracas.create!(restaurante_id: restaurante.id, piso: 1, modo_acesso: "normal")
  end
  let(:turno) do
    turnos.create!(nome: "Almoco", inicio: "11:00", fim: "14:00", preco: 4.50)
  end

  def criar_estudante(matricula)
    usuarios.create!(
      matricula: matricula, nome: "Aluno #{matricula}",
      senha_hash: "hash-#{matricula}", perfil: "estudante", saldo: 0
    )
  end

  def criar_recarga(usuario:, data_hora:, valor:)
    recargas.create!(
      usuario_matricula: usuario.matricula, data_hora: Time.zone.parse(data_hora),
      valor: valor, metodo: "PIX", status: "concluida"
    )
  end

  def criar_acesso(usuario:, data_hora:)
    instante = Time.zone.parse(data_hora)
    acessos.create!(
      usuario_matricula: usuario.matricula,
      catraca_id: catraca.id,
      turno_id: turno.id,
      data_hora: instante,
      status: "liberado",
      passagem_em: instante,
      valor_debitado: 4.50
    )
  end

  def exportar(usuario: estudante, gerador_pdf: GeradorPdfHistoricoMock)
    described_class.call(
      usuario: usuario, mes: 5, ano: 2026,
      recargas_model: recargas, acessos_model: acessos,
      gerador_pdf: gerador_pdf
    )
  end

  it "inclui os seis lancamentos de maio, mesmo que a tela mostre cinco por pagina" do
    6.times do |i|
      criar_recarga(
        usuario: estudante,
        data_hora: format("2026-05-%02d 12:00", i + 1),
        valor: i + 1
      )
    end
    criar_recarga(usuario: estudante, data_hora: "2026-04-30 12:00", valor: 99)

    resultado = exportar

    expect(resultado.simulado).to be(true)
    expect(resultado.lancamentos.size).to eq(6)
    expect(resultado.lancamentos.map { |item| item[:valor] }).not_to include(99.to_d)
  end

  it "permite exportar um periodo sem lancamentos" do
    resultado = exportar

    expect(resultado.lancamentos).to be_empty
    expect(resultado.conteudo).to include("Total de lancamentos: 0")
    expect(resultado.tipo_mime).to eq("text/plain")
  end

  it "nao inclui os registros de outros estudantes" do
    criar_recarga(usuario: estudante, data_hora: "2026-05-02 12:00", valor: 10)
    criar_recarga(usuario: outro_estudante, data_hora: "2026-05-03 12:00", valor: 20)

    resultado = exportar

    expect(resultado.lancamentos.size).to eq(1)
    expect(resultado.lancamentos.first[:valor]).to eq(10.to_d)
  end

  it "inclui recargas e passagens confirmadas no historico" do
    criar_recarga(usuario: estudante, data_hora: "2026-05-01 09:00", valor: 20)
    criar_acesso(usuario: estudante, data_hora: "2026-05-01 12:00")
    criar_acesso(usuario: estudante, data_hora: "2026-05-02 12:00")

    resultado = exportar

    expect(resultado.lancamentos.map { |item| item[:tipo] }).to eq(%w[recarga acesso acesso])
    expect(resultado.lancamentos.map { |item| item[:valor] }).to eq([20.to_d, 4.5.to_d, 4.5.to_d])
    expect(resultado.lancamentos.last[:status]).to eq("liberado")
  end

  it "delega a geracao do documento a um adaptador substituivel" do
    criar_recarga(usuario: estudante, data_hora: "2026-05-10 12:00", valor: 15)
    gerador = class_double(GeradorPdfHistoricoMock)

    expect(gerador).to receive(:call).with(
      usuario: estudante,
      lancamentos: array_including(hash_including(tipo: "recarga", valor: 15.to_d))
    ).and_return(:resultado_do_gerador)

    expect(exportar(gerador_pdf: gerador)).to eq(:resultado_do_gerador)
  end
end
