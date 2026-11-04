require "rails_helper"

RSpec.describe "Relatório global de acessos", type: :model do
  def criar_usuario(matricula, perfil)
    Usuario.create!(matricula: matricula, nome: perfil, senha_hash: "senha-hash", perfil: perfil, saldo: 0)
  end

  let(:administrador) { criar_usuario("999900001", "administrador") }
  let(:estudante) { criar_usuario("221012345", "estudante") }

  before do
    conexao = ActiveRecord::Base.connection
    @restaurantes = (1..3).map do |piso|
      conexao.insert("INSERT INTO restaurantes (nome) VALUES ('RU Darcy Ribeiro - Piso #{piso}')")
    end
    @catracas = [0, 0, 1, 1, 2].map do |indice|
      conexao.insert(<<~SQL.squish)
        INSERT INTO catracas (restaurante_id, piso, modo_acesso)
        VALUES (#{Integer(@restaurantes.fetch(indice))}, #{indice + 1}, 'comum')
      SQL
    end
    turno = Turno.create!(nome: "Almoço", inicio: "11:00", fim: "14:30", preco: "4.50")
    outro_estudante = criar_usuario("231045229", "estudante")
    @acessos = [0, 2, 4, 3, 3, 1].each_with_index.map do |indice, posicao|
      Acesso.create!(
        usuario: posicao.even? ? estudante : outro_estudante,
        turno: turno,
        catraca_id: @catracas.fetch(indice),
        data_hora: Time.current,
        status: posicao.even? ? "liberado" : "bloqueado",
        valor_debitado: 0
      )
    end
  end

  it "retorna todos os seis acessos sem filtros, de diferentes estudantes e status" do
    resultado = Acesso.relatorio_global(ator: administrador)

    expect(resultado.map(&:id)).to match_array(@acessos.map(&:id))
  end

  it "retorna somente os dois acessos do restaurante selecionado" do
    resultado = Acesso.relatorio_global(ator: administrador, restaurante_id: @restaurantes[0])

    expect(resultado.map(&:id)).to match_array([@acessos[0].id, @acessos[5].id])
  end

  it "retorna somente o acesso da catraca selecionada" do
    resultado = Acesso.relatorio_global(ator: administrador, catraca_id: @catracas[4])

    expect(resultado.map(&:id)).to eq([@acessos[2].id])
  end

  it "retorna vazio para restaurante e catraca incompatíveis" do
    resultado = Acesso.relatorio_global(
      ator: administrador, restaurante_id: @restaurantes[0], catraca_id: @catracas[4]
    )

    expect(resultado).to be_empty
  end

  it "aplica a interseção de restaurante e catraca compatíveis" do
    resultado = Acesso.relatorio_global(
      ator: administrador, restaurante_id: @restaurantes[1], catraca_id: @catracas[3]
    )

    expect(resultado.map(&:id)).to match_array([@acessos[3].id, @acessos[4].id])
  end

  it "recusa a consulta de um estudante" do
    expect { Acesso.relatorio_global(ator: estudante) }.to raise_error do |erro|
      expect(erro.class.name).to eq("Acesso::PermissaoNegada")
    end
  end

  it "recusa a consulta sem ator identificado" do
    expect { Acesso.relatorio_global(ator: nil) }.to raise_error do |erro|
      expect(erro.class.name).to eq("Acesso::PermissaoNegada")
    end
  end

  it "agrupa todos os acessos pelo restaurante correspondente" do
    grupos = Acesso.relatorio_global(ator: administrador, agrupar_por: :restaurante)

    expect(grupos.transform_values { |acessos| acessos.map(&:id).sort }).to eq(
      @restaurantes[0] => [@acessos[0].id, @acessos[5].id].sort,
      @restaurantes[1] => [@acessos[1].id, @acessos[3].id, @acessos[4].id].sort,
      @restaurantes[2] => [@acessos[2].id]
    )
  end

  it "agrupa por catraca preservando o filtro de restaurante" do
    grupos = Acesso.relatorio_global(
      ator: administrador, restaurante_id: @restaurantes[1], agrupar_por: :catraca
    )

    expect(grupos.transform_values { |acessos| acessos.map(&:id).sort }).to eq(
      @catracas[2] => [@acessos[1].id],
      @catracas[3] => [@acessos[3].id, @acessos[4].id].sort
    )
  end
end
