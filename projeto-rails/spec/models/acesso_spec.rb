require "rails_helper"

RSpec.describe Acesso, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:turno) do
    Turno.create!(nome: "Almoço", inicio: "11:00", fim: "14:30", preco: "4.50")
  end

  def criar_acesso(matricula:, saldo:)
    Usuario.create!(
      matricula: matricula,
      nome: "Estudante #{matricula}",
      senha_hash: "senha-hash",
      perfil: "estudante",
      saldo: saldo
    )

    conexao = ActiveRecord::Base.connection
    restaurante_id = conexao.insert("INSERT INTO restaurantes (nome) VALUES ('RU Darcy Ribeiro')")
    catraca_id = conexao.insert(<<~SQL.squish)
      INSERT INTO catracas (restaurante_id, piso, modo_acesso)
      VALUES (#{Integer(restaurante_id)}, 1, 'comum')
    SQL

    described_class.create!(
      usuario: Usuario.find(matricula),
      turno: turno,
      catraca_id: catraca_id,
      data_hora: Time.current,
      status: "pendente",
      passagem_em: nil,
      valor_debitado: 0
    )
  end

  describe "#liberacao_permitida?" do
    [
      ["saldo suficiente", "221012345", "15.50", true],
      ["saldo igual ao preço", "250000001", "4.50", true],
      ["saldo insuficiente", "251123339", "3.50", false],
      ["saldo zerado", "232421234", "0.00", false]
    ].each do |cenario, matricula, saldo, permitido|
      it "retorna #{permitido} para #{cenario} sem debitar antes da passagem" do
        acesso = criar_acesso(matricula: matricula, saldo: saldo)

        expect(acesso.liberacao_permitida?).to eq(permitido)
        expect(acesso.usuario.reload.saldo).to eq(BigDecimal(saldo))
        expect(acesso.reload.passagem_em).to be_nil
        expect(acesso.valor_debitado).to eq(0.to_d)
      end
    end
  end

  describe "#confirmar_passagem!" do
    it "não debita novamente ao confirmar usando outra instância do mesmo acesso" do
      acesso = criar_acesso(matricula: "221012345", saldo: "15.50")
      segunda_instancia = described_class.find(acesso.id)

      expect(acesso.confirmar_passagem!).to be(true)
      expect(segunda_instancia.confirmar_passagem!).to be(false)
      expect(acesso.usuario.reload.saldo).to eq(11.to_d)
    end

    it "não confirma uma tentativa bloqueada" do
      acesso = criar_acesso(matricula: "221012345", saldo: "15.50")
      acesso.update!(status: "bloqueado")

      expect(acesso.confirmar_passagem!).to be(false)
      expect(acesso.reload.passagem_em).to be_nil
      expect(acesso.usuario.reload.saldo).to eq(15.5.to_d)
    end

    [
      ["221012345", "15.50", "11.00"],
      ["231045229", "45.00", "40.50"]
    ].each do |matricula, saldo_inicial, saldo_final|
      it "debita R$ 4,50 na passagem e altera o saldo de #{saldo_inicial} para #{saldo_final}" do
        acesso = criar_acesso(matricula: matricula, saldo: saldo_inicial)

        travel_to(Time.zone.local(2026, 10, 16, 12, 0, 0)) do
          expect(acesso.confirmar_passagem!).to be(true)

          expect(acesso.usuario.reload.saldo).to eq(BigDecimal(saldo_final))
          expect(acesso.reload.passagem_em).to eq(Time.current)
          expect(acesso.valor_debitado).to eq(BigDecimal("4.50"))
        end
      end
    end
  end
end
