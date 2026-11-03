class Acesso < ApplicationRecord
  belongs_to :usuario, foreign_key: :usuario_matricula, primary_key: :matricula
  belongs_to :turno

  def liberacao_permitida?
    usuario.reload.saldo_suficiente_para?(turno)
  end

  def confirmar_passagem!
    self.class.transaction do
      preco = turno.preco
      debitos = Usuario.where(matricula: usuario_matricula)
                       .where("saldo >= ?", preco)
                       .update_all(["saldo = saldo - ?", preco])

      next false if debitos.zero?

      update!(passagem_em: Time.current, valor_debitado: preco)
      usuario.reload
      true
    end
  end
end
