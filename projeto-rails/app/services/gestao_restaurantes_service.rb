class GestaoRestaurantesService
  class AcessoNegado < StandardError; end

  # Lista restaurantes por nome com suas catracas.
  # Sem argumentos; retorna relação consultável, sem alterar registros.
  def self.listar_restaurantes
    Restaurante.includes(:catracas).order(:nome)
  end

  # Cadastra um restaurante com o usuário e o nome recebidos.
  # Retorna Restaurante ou lança erro; exige administrador e grava no banco.
  def self.cadastrar_restaurante(usuario:, nome:)
    exigir_administrador!(usuario)
    Restaurante.create!(nome: nome)
  end

  # Atualiza o nome do restaurante recebido, autorizado pelo usuário recebido.
  # Retorna Restaurante ou lança erro; exige administrador e grava no banco.
  def self.editar_restaurante(usuario:, restaurante:, nome:)
    exigir_administrador!(usuario)
    restaurante.update!(nome: nome)
    restaurante
  end

  # Exclui o restaurante recebido, autorizado pelo usuário recebido.
  # Retorna o registro excluído ou lança erro; exige administrador e altera o banco.
  def self.remover_restaurante(usuario:, restaurante:)
    exigir_administrador!(usuario)
    restaurante.destroy!
  end

  # Cadastra catraca com usuário, restaurante, piso e modalidade recebidos.
  # Retorna Catraca ou lança erro; exige administrador e grava no banco.
  def self.cadastrar_catraca(usuario:, restaurante:, piso:, modo_acesso: 'normal')
    exigir_administrador!(usuario)
    restaurante.catracas.create!(piso: piso, modo_acesso: modo_acesso)
  end

  # Atualiza catraca com usuário, piso e modalidade opcional recebidos.
  # Retorna Catraca ou lança erro; exige administrador e grava no banco.
  def self.editar_catraca(usuario:, catraca:, piso:, modo_acesso: nil)
    exigir_administrador!(usuario)
    atributos = { piso: piso }
    atributos[:modo_acesso] = modo_acesso unless modo_acesso.nil?
    catraca.update!(atributos)
    catraca
  end

  # Exclui a catraca recebida, autorizado pelo usuário recebido.
  # Retorna o registro excluído ou lança erro; exige administrador e altera o banco.
  def self.remover_catraca(usuario:, catraca:)
    exigir_administrador!(usuario)
    catraca.destroy!
  end

  # Verifica a permissão administrativa do usuário recebido.
  # Retorna nil ou lança AcessoNegado; não altera registros.
  def self.exigir_administrador!(usuario)
    return if usuario&.perfil == 'administrador'

    raise AcessoNegado, 'Operacao restrita a administradores'
  end
  private_class_method :exigir_administrador!
end
