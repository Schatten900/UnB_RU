require "rails_helper"

RSpec.describe "Extrato e histórico do estudante", type: :model do
  def criar_usuario(matricula)
    Usuario.create!(
      matricula: matricula,
      nome: "Estudante #{matricula}",
      senha_hash: "senha-hash-#{matricula}",
      perfil: "estudante",
      saldo: 0
    )
  end

  def criar_recarga(usuario:, data_hora:, valor:)
    Recarga.create!(
      usuario: usuario,
      data_hora: data_hora,
      valor: valor,
      metodo: "PIX",
      status: "concluida"
    )
  end

  def criar_turno(nome)
    Turno.create!(nome: nome, inicio: "11:00", fim: "14:30", preco: 4.50)
  end

  def criar_acesso(usuario:, turno:, data_hora:, valor:)
    garantir_catraca
    Acesso.create!(
      usuario: usuario,
      catraca_id: 1,
      turno: turno,
      data_hora: data_hora,
      status: "liberado",
      passagem_em: data_hora,
      valor_debitado: valor
    )
  end

  def garantir_catraca
    conexao = ActiveRecord::Base.connection
    conexao.execute("INSERT OR IGNORE INTO restaurantes (id, nome) VALUES (1, 'RU Darcy Ribeiro')")
    conexao.execute(<<~SQL.squish)
      INSERT OR IGNORE INTO catracas (id, restaurante_id, piso, modo_acesso)
      VALUES (1, 1, 0, 'comum')
    SQL
  end

  it "retorna somente as recargas do estudante com data e valor" do
    estudante = criar_usuario("221012345")
    outro_estudante = criar_usuario("231045229")
    primeira = criar_recarga(usuario: estudante, data_hora: Time.zone.parse("2026-10-10 09:00"), valor: 20)
    segunda = criar_recarga(usuario: estudante, data_hora: Time.zone.parse("2026-10-12 10:00"), valor: 15)
    criar_recarga(usuario: outro_estudante, data_hora: Time.zone.parse("2026-10-12 11:00"), valor: 45)

    extrato = estudante.extrato_recargas

    expect(extrato.ids).to match_array([primeira.id, segunda.id])
    expect(extrato.pluck(:data_hora, :valor)).to match_array([
      [primeira.data_hora, 20.to_d],
      [segunda.data_hora, 15.to_d]
    ])
  end

  it "retorna somente as refeições do estudante com data, turno e valor debitado" do
    estudante = criar_usuario("221012345")
    outro_estudante = criar_usuario("231045229")
    almoco = criar_turno("Almoço")
    jantar = criar_turno("Jantar")
    primeira = criar_acesso(
      usuario: estudante,
      turno: almoco,
      data_hora: Time.zone.parse("2026-10-10 12:00"),
      valor: 4.50
    )
    segunda = criar_acesso(
      usuario: estudante,
      turno: jantar,
      data_hora: Time.zone.parse("2026-10-12 18:00"),
      valor: 4.50
    )
    criar_acesso(
      usuario: outro_estudante,
      turno: almoco,
      data_hora: Time.zone.parse("2026-10-12 12:30"),
      valor: 4.50
    )

    historico = estudante.historico_refeicoes

    expect(historico.map(&:id)).to match_array([primeira.id, segunda.id])
    expect(historico.map(&:data_hora)).to match_array([primeira.data_hora, segunda.data_hora])
    expect(historico.map { |acesso| acesso.turno.nome }).to match_array(["Almoço", "Jantar"])
    expect(historico.map(&:valor_debitado)).to all(eq(4.5.to_d))
  end

  it "retorna coleções vazias quando o estudante não possui registros" do
    estudante = criar_usuario("232421234")

    expect(estudante.extrato_recargas).to be_empty
    expect(estudante.historico_refeicoes).to be_empty
  end
end
