# Gerencia a tela de admin de vagas e cotas FastPass.
#
# Exibe cotas por restaurante e data, delega sua configuração ao serviço
class VagasFastpassController < ApplicationController
  before_action :exigir_administrador

  # Exibe as janelas e as cotas do restaurante na data solicitada.
  #
  # Usa +restaurante_id+ para selecionar o restaurante e +data+ 
  # Sem esses parâmetros, utiliza o primeiro restaurante por nome e a data atual.
  # Redireciona para a grade com alerta quando a data é inválida.
  def index
    carregar_restaurante
    @data = Date.iso8601(params.fetch(:data, Date.current.to_s))
    @janelas = TimeFrame.includes(:turno).order(:inicio, :id)
    carregar_cotas
  rescue Date::Error
    redirect_to admin_vagas_fastpass_path, alert: "Informe uma data válida."
  end

  # Salva as cotas e retorna a grade do restaurante e da data selecionados.
  #
  # Parâmetros da requisição:
  # - +restaurante_id+: identificador do restaurante que receberá as cotas.
  # - +data+: data do sorteio.
  # - +cota_diaria+: total diário ofertado pelo restaurante.
  # - +cotas+: valores indexados pelos identificadores das janelas.
  #
  # Delega as regras ao ConfiguracaoCotasFastpassService. ArgumentError e
  # ActiveRecord::RecordInvalid causam redirecionamento com a mensagem do erro.
  # Lança ActiveRecord::RecordNotFound se o restaurante não existir.
  def aplicar
    restaurante = Restaurante.find(params[:restaurante_id])
    ConfiguracaoCotasFastpassService.call(
      restaurante: restaurante,
      data: params[:data],
      cota_diaria: params[:cota_diaria],
      cotas: parametros_cotas
    )
    redirecionar_cotas_salvas(restaurante)
  rescue ArgumentError, ActiveRecord::RecordInvalid => erro
    redirect_to admin_vagas_fastpass_path(restaurante_id: params[:restaurante_id]), alert: erro.message
  end

  # Executa o sorteio indicado em +sorteio_id+ e agenda a notificação do resultado.
  #
  # O serviço processa todos os restaurantes configurados no sorteio.
  # Redireciona à grade da data do sorteio, preservando +restaurante_id+.
  # ArgumentError causa redirecionamento com alerta; sorteio inexistente
  # gera ActiveRecord::RecordNotFound.
  def sortear
    sorteio = Sorteio.find(params[:sorteio_id])
    FastPasses::RealizarSorteioService.call(sorteio: sorteio)
    NotificarFastPassJob.perform_later(sorteio.id)
    redirect_to admin_vagas_fastpass_path(data: sorteio.data, restaurante_id: params[:restaurante_id]),
      notice: "Sorteio concluído para todos os restaurantes configurados. Resultados disponíveis aos estudantes."
  rescue ArgumentError => erro
    redirect_to admin_vagas_fastpass_path(data: sorteio&.data, restaurante_id: params[:restaurante_id]), alert: erro.message
  end

  private

  # Retorna as cotas enviadas, indexadas pelos IDs das janelas.
  #
  # Permite chaves dinâmicas porque cada janela possui seu próprio ID.
  # A validação dos IDs e valores permanece no serviço de configuração.
  # Sem o parâmetro +cotas+, retorna um Hash vazio.
  def parametros_cotas
    params.fetch(:cotas, ActionController::Parameters.new).permit!.to_h
  end

  # Redireciona à grade do +restaurante+ e da data com confirmação de sucesso.
  # Usa a data recebida na requisição e informa que as cotas foram salvas.
  def redirecionar_cotas_salvas(restaurante)
    redirect_to admin_vagas_fastpass_path(
      restaurante_id: restaurante.id,
      data: params[:data]
    ), notice: "Cotas salvas para o sorteio."
  end

  # Disponibiliza os restaurantes e seleciona o solicitado em +restaurante_id+.
  #
  # Sem restaurante informado, utiliza o primeiro por nome.
  # Lança ActiveRecord::RecordNotFound se o ID informado não existir.
  def carregar_restaurante
    @restaurantes = Restaurante.order(:nome)
    @restaurante = if params[:restaurante_id].present?
      @restaurantes.find(params[:restaurante_id])
    else
      @restaurantes.first
    end
  end

  # Carrega o sorteio da data e as cotas do restaurante selecionado.
  #
  # Sem sorteio ou restaurante, utiliza cotas vazias e total diário zero.
  # Converte as chaves das cotas para Integer e disponibiliza sua soma na view.
  def carregar_cotas
    @sorteio = Sorteio.find_by(data: @data)
    @cotas = if @sorteio && @restaurante
      @sorteio.cotas_do_restaurante(@restaurante).transform_keys(&:to_i)
    else
      {}
    end

    @cota_diaria = @cotas.values.sum
  end

  # Permite as ações somente para administrador autenticado.
  # Redireciona os demais usuários ao login com alerta e interrompe a ação.
  def exigir_administrador
    return if usuario_atual&.administrador?

    redirect_to login_path, alert: "Acesso não autorizado."
  end
end
