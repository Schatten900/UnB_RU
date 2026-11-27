##
# Controller responsável pela exibição do cardápio disponível
# para o usuário autenticado.
#
# Apresenta o cardápio correspondente ao turno vigente, os turnos
# cadastrados e uma estimativa da quantidade de refeições que o
# usuário pode adquirir com seu saldo atual.
#
class CardapioController < ApplicationController
  ##
  # Verifica se existe um usuário autenticado antes de executar
  # as actions do controller.
  before_action :exigir_usuario

  ##
  # Exibe o cardápio correspondente ao turno vigente.
  #
  # Carrega o cardápio utilizando o serviço CardapioServices,
  # consulta os turnos cadastrados e calcula a quantidade estimada
  # de refeições que o usuário pode adquirir com seu saldo,
  # considerando o preço da refeição do cardápio encontrado.
  #
  # A estimativa é calculada apenas quando existe um usuário
  # autenticado, um cardápio associado a um turno e um preço positivo.
  #
  # @return [void] Não retorna um valor de negócio.
  #
  # Efeito colateral: Realiza consultas ao banco de dados,
  # inicializa as variáveis de instância utilizadas pela view
  # e disponibiliza os dados necessários para a exibição do cardápio.
  def index
    @cardapio = CardapioServices.call
    @turnos = Turno.order(:inicio)

    @refeicoes_estimadas = if usuario_atual && @cardapio&.turno&.preco&.positive?
                             (usuario_atual.saldo / @cardapio.turno.preco).floor
                           end
  end

  private

  ##
  # Verifica se existe um usuário autenticado na aplicação.
  #
  # Caso não exista um usuário autenticado, redireciona para
  # a página de login.
  #
  # @return [void] Não retorna um valor de negócio.
  #
  # Efeito colateral: Quando não existe usuário autenticado,
  # realiza um redirecionamento para a página de login.
  # Quando existe, permite a continuidade da requisição.
  def exigir_usuario
    redirect_to login_path unless usuario_atual
  end
end
