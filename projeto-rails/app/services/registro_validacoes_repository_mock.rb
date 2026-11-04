# Repositorio em memoria para simular o registro de tentativas de validacao.
# Um Acesso e criado somente quando a passagem pela catraca e confirmada.
class RegistroValidacoesRepositoryMock
  Registro = Struct.new(:catraca_id, :usuario_matricula, :status, :data_hora,
                        keyword_init: true)

  def initialize
    @registros = []
  end

  def registrar(catraca_id:, usuario_matricula:, status:, data_hora: Time.current)
    registro = Registro.new(catraca_id: catraca_id,
                            usuario_matricula: usuario_matricula,
                            status: status,
                            data_hora: data_hora)
    @registros << registro
    registro
  end

  def listar(catraca_id:)
    @registros.select { |registro| registro.catraca_id == catraca_id }
              .sort_by(&:data_hora)
              .reverse
  end
end
