module Admin
  class RestaurantesController < BaseController
    def index
      @restaurantes = GestaoRestaurantesService.listar_restaurantes.to_a
      @total_catracas = Catraca.count
      @total_fastpass = Catraca.where(modo_acesso: "fastpass").count
    end

    def create
      GestaoRestaurantesService.cadastrar_restaurante(
        usuario: usuario_atual,
        nome: restaurante_params[:nome]
      )
      redirect_to admin_restaurantes_path, notice: "Restaurante cadastrado com sucesso."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_restaurantes_path, alert: e.record.errors.full_messages.to_sentence
    end

    def update
      restaurante = Restaurante.find(params[:id])
      GestaoRestaurantesService.editar_restaurante(
        usuario: usuario_atual,
        restaurante: restaurante,
        nome: restaurante_params[:nome]
      )
      redirect_to admin_restaurantes_path, notice: "Restaurante atualizado com sucesso."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_restaurantes_path, alert: e.record.errors.full_messages.to_sentence
    end

    def destroy
      restaurante = Restaurante.find(params[:id])
      GestaoRestaurantesService.remover_restaurante(
        usuario: usuario_atual, restaurante: restaurante
      )
      redirect_to admin_restaurantes_path, notice: "Restaurante removido com sucesso."
    rescue ActiveRecord::RecordNotDestroyed
      redirect_to admin_restaurantes_path,
                  alert: "Remova primeiro as catracas associadas ao restaurante."
    rescue ActiveRecord::InvalidForeignKey
      redirect_to admin_restaurantes_path,
                  alert: "Nao foi possivel remover o restaurante: existem registros associados."
    end

    private

    def restaurante_params
      params.require(:restaurante).permit(:nome)
    end
  end
end
