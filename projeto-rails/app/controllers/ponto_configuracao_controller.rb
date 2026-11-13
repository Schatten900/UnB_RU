class PontoConfiguracaoController < ApplicationController
    before_action :exigir_funcionario
    rescue_from ActiveRecord::ConnectionNotEstablished,
                ActiveRecord::ConnectionTimeoutError,
                with: :render_indisponibilidade

    def new
        carregar_restaurantes
    end

    def create
        restaurante = PontoConfiguracaoService.call(restaurante_id: params[:restaurante_id])
        catraca = restaurante&.catracas&.find_by(id: params[:catraca_id])

        unless restaurante && catraca
            carregar_restaurantes
            flash.now[:alert] = "Selecione um restaurante e uma catraca cadastrados para essa unidade."
            return render :new, status: :unprocessable_content
        end

        session[:restaurante_id] = restaurante.id
        session[:catraca_id] = catraca.id
        Rails.logger.info(
            "Restaurante #{restaurante.id} e catraca #{catraca.id} selecionados por funcionário #{usuario_atual.matricula}"
        )

        redirect_to operator_ponto_configuracao_path, notice: "Ponto de acesso configurado com sucesso."
    end

    private

    def render_indisponibilidade(exception)
        Rails.logger.error("Falha de conexão ao configurar ponto de acesso: #{exception.message}")
        render :indisponivel, status: :service_unavailable
    end

    def carregar_restaurantes
        @restaurantes = Restaurante.includes(:catracas).order(:id)
        @restaurante_atual = @restaurantes.find_by(id: restaurante_atual&.id) || @restaurantes.first
        @catracas = @restaurante_atual&.catracas&.order(:piso, :id) || Catraca.none
        @catraca_atual = @catracas.find_by(id: session[:catraca_id]) || @catracas.first
    end
end
