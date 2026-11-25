module Admin
  class CatracasController < BaseController
    # Cadastra uma catraca no restaurante informado na requisição.
    # Retorna redirecionamento com sucesso ou erro; grava no banco.
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

    # Atualiza piso e modalidade da catraca identificada na requisição.
    # Retorna redirecionamento com sucesso ou erro; grava no banco.
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

    # Remove a catraca indicada quando não possui registros impeditivos.
    # Retorna redirecionamento com sucesso ou erro; exclui o registro quando permitido.
    def destroy
      catraca = Catraca.find(params[:id])
      GestaoRestaurantesService.remover_catraca(usuario: usuario_atual, catraca: catraca)
      redirect_to admin_restaurantes_path, notice: "Catraca removida com sucesso."
    rescue ActiveRecord::InvalidForeignKey, ActiveRecord::RecordNotDestroyed
      redirect_to admin_restaurantes_path,
                  alert: "Nao foi possivel remover a catraca: existem acessos associados."
    end

    private

    # Seleciona restaurante, piso e modalidade permitidos na requisição.
    # Sem argumentos; retorna parâmetros permitidos, sem acessar o banco.
    def catraca_params
      params.require(:catraca).permit(:restaurante_id, :piso, :modo_acesso)
    end
  end
end
