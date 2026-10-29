class CardapioController < ApplicationController

    def index

        @cardapio = CardapioServices.call

    end

end
