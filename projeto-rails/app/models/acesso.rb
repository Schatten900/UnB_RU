# models/acesso.rb
class Acesso < ApplicationRecord
  class PermissaoNegada < StandardError; end

  belongs_to :usuario, foreign_key: :usuario_matricula, primary_key: :matricula
  belongs_to :turno
  belongs_to :catraca
  belongs_to :inscricao_fastpass, optional: true

  def self.relatorio_global(ator:, restaurante_id: nil, catraca_id: nil, agrupar_por: nil)
    unless ator&.perfil == 'administrador'
      raise PermissaoNegada, 'Você não tem permissão para consultar o relatório global'
    end

    acessos = all
    acessos = acessos.joins(:catraca).where(catracas: { restaurante_id: restaurante_id }) if restaurante_id.present?
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
    if inscricao_fastpass_id
      InscricaoFastpass.find(inscricao_fastpass_id).with_lock do
        next false if self.class.where(inscricao_fastpass_id: inscricao_fastpass_id).where.not(passagem_em: nil).exists?

        confirmar_passagem_pendente!(agora: agora)
      end
    else
      confirmar_passagem_pendente!(agora: agora)
    end
  end

  private

  # Confirma o acesso pendente em uma transação
  #
  # +agora+ é o instante da passagem. Retorna true na confirmação ou false
  # quando o acesso não pode ser reservado ou o saldo é insuficiente.
  def confirmar_passagem_pendente!(agora:)
    self.class.transaction(requires_new: true) do
      next false unless reservar_passagem(agora)

      preco = turno.preco
      raise ActiveRecord::Rollback unless debitar_saldo(preco)

      registrar_passagem(agora, preco)
      atualizar_faturamento(preco)
      usuario.reload
      true
    end || false
  end

  # Reserva a passagem em +agora+ somente se o acesso estiver pendente e não usado.
  # Retorna true se a atualização condicional afetou o registro.
  def reservar_passagem(agora)
    self.class.where(id: id, status: 'pendente', passagem_em: nil)
        .update_all(passagem_em: agora)
        .positive?
  end

  # Debita +preco+ somente se o saldo no banco for suficiente.
  # Retorna true quando o débito foi realizado.
  def debitar_saldo(preco)
    Usuario.where(matricula: usuario_matricula)
           .where('saldo >= ?', preco)
           .update_all(['saldo = saldo - ?', preco])
           .positive?
  end

  # Persiste o horário +agora+, o valor debitado +preco+ e o status liberado.
  # Propaga erros de persistência para desfazer a transação chamadora.
  def registrar_passagem(agora, preco)
    update!(passagem_em: agora, valor_debitado: preco, status: 'liberado')
  end

  # Incrementa o faturamento do restaurante pelo +preco+ na transação chamadora.
  def atualizar_faturamento(preco)
    Restaurante.where(id: catraca.restaurante_id)
               .update_all(['faturamento = faturamento + ?', preco])
  end
end
