class CardapioController < ApplicationController
    before_action :exigir_usuario

    def index

        @cardapio = CardapioServices.call
        @turnos = Turno.order(:inicio)
        @refeicoes_estimadas = if usuario_atual && @cardapio&.turno&.preco&.positive?
            (usuario_atual.saldo / @cardapio.turno.preco).floor
        end

    end

    private

    def exigir_usuario
        redirect_to login_path unless usuario_atual
    end
end
