# Simula o comando de liberacao de uma catraca fisica.
class LiberadorCatracaMock
  attr_reader :comandos

  def initialize
    @comandos = []
  end

  def liberar(catraca_id:)
    @comandos << catraca_id
    true
  end
end
