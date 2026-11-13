# Compatibilidade com os consumidores da consulta existente na sprint-2.
class HistoricoEstudanteService
  ZONA = "America/Sao_Paulo".freeze

  def self.call(usuario:, filtros: {}, agora: Time.current)
    ExtratoRefeicoesService.call(usuario: usuario, filtros: filtros, agora: agora).lancamentos
  end
end
