module Admin
  class CatracasController < BaseController
    def create
      atributos = catraca_params
      restaurante = Restaurante.find(atributos[:restaurante_id])
      GestaoRestaurantesService.cadastrar_catraca(
        usuario: usuario_atual,
        restaurante: restaurante,
        piso: atributos[:piso],
        modo_acesso: atributos[:modo_acesso]
      )
      redirect_to admin_restaurantes_path, notice: "Catraca cadastrada com sucesso."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_restaurantes_path, alert: e.record.errors.full_messages.to_sentence
    end

    def update
      catraca = Catraca.find(params[:id])
      atributos = catraca_params
      GestaoRestaurantesService.editar_catraca(
        usuario: usuario_atual,
        catraca: catraca,
        piso: atributos[:piso],
        modo_acesso: atributos[:modo_acesso]
      )
      redirect_to admin_restaurantes_path, notice: "Catraca atualizada com sucesso."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_restaurantes_path, alert: e.record.errors.full_messages.to_sentence
    end

    def destroy
      catraca = Catraca.find(params[:id])
      GestaoRestaurantesService.remover_catraca(usuario: usuario_atual, catraca: catraca)
      redirect_to admin_restaurantes_path, notice: "Catraca removida com sucesso."
    rescue ActiveRecord::InvalidForeignKey, ActiveRecord::RecordNotDestroyed
      redirect_to admin_restaurantes_path,
                  alert: "Nao foi possivel remover a catraca: existem acessos associados."
    end

    private

    def catraca_params
      params.require(:catraca).permit(:restaurante_id, :piso, :modo_acesso)
    end
  end
end
