# Compatibilidade com os consumidores da consulta existente na sprint-2.
class HistoricoEstudanteService
  ZONA = "America/Sao_Paulo".freeze

  # Consulta o histórico do usuário com os filtros e o horário de referência recebidos.
  # Retorna Array de lançamentos; consulta o banco sem gravar.
  def self.call(usuario:, filtros: {}, agora: Time.current)
    ExtratoRefeicoesService.call(usuario: usuario, filtros: filtros, agora: agora).lancamentos
  end
end
