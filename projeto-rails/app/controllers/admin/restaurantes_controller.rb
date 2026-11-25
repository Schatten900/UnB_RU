module Admin
  class RestaurantesController < BaseController
    # Lista restaurantes, catracas e seus indicadores.
    # Sem argumentos; retorna HTML e consulta o banco.
    def index
      @restaurantes = GestaoRestaurantesService.listar_restaurantes.to_a
      @total_catracas = Catraca.count
      @total_fastpass = Catraca.where(modo_acesso: "fastpass").count
    end

    # Cadastra o restaurante informado na requisição.
    # Retorna redirecionamento com sucesso ou erro; grava no banco.
    def create
      GestaoRestaurantesService.cadastrar_restaurante(
        usuario: usuario_atual,
        nome: restaurante_params[:nome]
      )
      redirect_to admin_restaurantes_path, notice: "Restaurante cadastrado com sucesso."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_restaurantes_path, alert: e.record.errors.full_messages.to_sentence
    end

    # Atualiza o restaurante identificado na requisição.
    # Retorna redirecionamento com sucesso ou erro; grava no banco.
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

    # Remove o restaurante indicado quando não há registros impeditivos.
    # Retorna redirecionamento com sucesso ou erro; exclui o registro quando permitido.
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

    # Seleciona o nome permitido nos parâmetros de restaurante.
    # Sem argumentos; retorna parâmetros permitidos, sem acessar o banco.
    def restaurante_params
      params.require(:restaurante).permit(:nome)
    end
  end
end
