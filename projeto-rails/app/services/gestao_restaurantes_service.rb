class GestaoRestaurantesService
  class AcessoNegado < StandardError; end

  def self.listar_restaurantes
    Restaurante.includes(:catracas).order(:nome)
  end

  def self.cadastrar_restaurante(usuario:, nome:)
    exigir_administrador!(usuario)
    Restaurante.create!(nome: nome)
  end

  def self.editar_restaurante(usuario:, restaurante:, nome:)
    exigir_administrador!(usuario)
    restaurante.update!(nome: nome)
    restaurante
  end

  def self.remover_restaurante(usuario:, restaurante:)
    exigir_administrador!(usuario)
    restaurante.destroy!
  end

  def self.cadastrar_catraca(usuario:, restaurante:, piso:, modo_acesso: "normal")
    exigir_administrador!(usuario)
    restaurante.catracas.create!(piso: piso, modo_acesso: modo_acesso)
  end

  def self.editar_catraca(usuario:, catraca:, piso:, modo_acesso: nil)
    exigir_administrador!(usuario)
    atributos = { piso: piso }
    atributos[:modo_acesso] = modo_acesso unless modo_acesso.nil?
    catraca.update!(atributos)
    catraca
  end

  def self.remover_catraca(usuario:, catraca:)
    exigir_administrador!(usuario)
    catraca.destroy!
  end

  def self.exigir_administrador!(usuario)
    return if usuario&.perfil == "administrador"

    raise AcessoNegado, "Operacao restrita a administradores"
  end
  private_class_method :exigir_administrador!
end
