#models/acesso.rb
class Acesso < ApplicationRecord
  class PermissaoNegada < StandardError; end

  belongs_to :usuario, foreign_key: :usuario_matricula, primary_key: :matricula
  belongs_to :turno
  belongs_to :catraca
  belongs_to :inscricao_fastpass, optional: true

  def self.relatorio_global(ator:, restaurante_id: nil, catraca_id: nil, agrupar_por: nil)
    # Validar com o time aqui se iremos utilizar a ideia das matriculas que começar com 9999 
    # Ou se podemos assumir só perfil=administrador.  
    unless ator&.perfil == "administrador"
      raise PermissaoNegada, "Você não tem permissão para consultar o relatório global"
    end

    acessos = all
    if restaurante_id.present?
      acessos = acessos.joins(:catraca).where(catracas: { restaurante_id: restaurante_id })
    end
    acessos = acessos.where(catraca_id: catraca_id) if catraca_id.present?

    case agrupar_por
    when nil
      acessos
    when :restaurante
      acessos.includes(:catraca).group_by { |acesso| acesso.catraca.restaurante_id }
    when :catraca
      acessos.group_by(&:catraca_id)
    else
      raise ArgumentError, "Agrupamento inválido: #{agrupar_por}"
    end
  end

  def liberacao_permitida?
    usuario.reload.saldo_suficiente_para?(turno)
  end

  def confirmar_passagem!(agora: Time.current)
    self.class.transaction do
      preco = turno.preco
      debitos = Usuario.where(matricula: usuario_matricula)
                       .where("saldo >= ?", preco)
                       .update_all(["saldo = saldo - ?", preco])

      next false if debitos.zero?

      update!(passagem_em: agora, valor_debitado: preco, status: "liberado")
      usuario.reload
      true
    end
  end
end
