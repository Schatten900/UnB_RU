# Simula o comando de liberacao de uma catraca fisica.
class LiberadorCatracaMock
  # Retorna os identificadores das liberações simuladas, sem alterar estado.
  attr_reader :comandos

  # Inicializa o liberador simulado sem argumentos.
  # Sem retorno de negócio; cria a lista de comandos em memória.
  def initialize
    @comandos = []
  end

  # Simula a liberação da catraca de catraca_id recebido.
  # Retorna true e registra o identificador na lista em memória.
  def liberar(catraca_id:)
    @comandos << catraca_id
    true
  end
end
