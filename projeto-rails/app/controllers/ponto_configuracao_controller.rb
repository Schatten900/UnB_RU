class PontoConfiguracaoController < ApplicationController
    before_action :exigir_funcionario

    def new
        carregar_restaurantes
    end

    def create
        restaurante = PontoConfiguracaoService.call(restaurante_id: params[:restaurante_id])

        unless restaurante
            carregar_restaurantes
            flash.now[:alert] = "Selecione um restaurante cadastrado."
            return render :new, status: :unprocessable_content
        end

        session[:restaurante_id] = restaurante.id
        Rails.logger.info(
            "Restaurante #{restaurante.id} selecionado por funcionário #{usuario_atual.matricula}"
        )

        redirect_to ponto_configuracao_path, notice: "Restaurante selecionado com sucesso."
    end

    private

    def carregar_restaurantes
        @restaurantes = Restaurante.order(:id)
        @restaurante_atual = restaurante_atual
    end
end