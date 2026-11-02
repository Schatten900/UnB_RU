require "rails_helper"

RSpec.describe HistoricoLocalService, type: :service do
  let(:funcionario) { double("Funcionario", funcionario?: true) }
  let(:estudante) { double("Estudante", funcionario?: false) }

  def criar_registro(tabela, atributos)
    modelo = Class.new(ApplicationRecord)
    modelo.table_name = tabela
    modelo.primary_key = "matricula" if tabela == "usuarios"
    modelo.create!(atributos)
  end

  before do
    restaurante = criar_registro("restaurantes", nome: "RU Teste")
    @catraca_04 = criar_registro("catracas", restaurante_id: restaurante.id,
                                piso: 1, modo_acesso: "normal")
    @catraca_02 = criar_registro("catracas", restaurante_id: restaurante.id,
                                piso: 2, modo_acesso: "normal")
    turno = criar_registro("turnos", nome: "Almoco", inicio: "11:00",
                          fim: "14:00", preco: 4.50)

    %w[221012345 231045229 251123339].each do |matricula|
      criar_registro("usuarios", matricula: matricula, nome: "Aluno #{matricula}",
                    senha_hash: "hash-de-teste", perfil: "estudante", saldo: 10)
    end

    data = Time.zone.parse("2026-10-15 12:00")
    @liberado = criar_registro("acessos", usuario_matricula: "221012345",
                              catraca_id: @catraca_04.id, turno_id: turno.id,
                              data_hora: data, status: "Liberado", valor_debitado: 4.50)
    @bloqueado = criar_registro("acessos", usuario_matricula: "231045229",
                               catraca_id: @catraca_04.id, turno_id: turno.id,
                               data_hora: data + 1.minute, status: "Bloqueado",
                               valor_debitado: 0)
    @outra_catraca = criar_registro("acessos", usuario_matricula: "251123339",
                                   catraca_id: @catraca_02.id, turno_id: turno.id,
                                   data_hora: data + 2.minutes, status: "Liberado",
                                   valor_debitado: 4.50)
  end

  it "mostra apenas os acessos da catraca selecionada, inclusive bloqueados" do
    acessos = described_class.call(usuario: funcionario, catraca_id: @catraca_04.id)

    expect(acessos.map(&:id)).to eq([@bloqueado.id, @liberado.id])
    expect(acessos.map(&:status)).to eq(["Bloqueado", "Liberado"])
    expect(acessos.map(&:usuario_matricula)).not_to include("251123339")
  end

  it "nao exibe registros da outra catraca" do
    acessos = described_class.call(usuario: funcionario, catraca_id: @catraca_02.id)

    expect(acessos.map(&:id)).to eq([@outra_catraca.id])
  end

  it "nega consulta por quem nao e funcionario" do
    expect do
      described_class.call(usuario: estudante, catraca_id: @catraca_04.id)
    end.to raise_error(HistoricoLocalService::AcessoNegado)
  end

  it "nao exibe nenhum acesso sem catraca selecionada" do
    acessos = described_class.call(usuario: funcionario, catraca_id: nil)

    expect(acessos).to be_empty
  end
end
