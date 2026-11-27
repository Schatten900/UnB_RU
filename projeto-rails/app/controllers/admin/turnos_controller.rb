module Admin
  class TurnosController < ApplicationController
    before_action :exigir_administrador

    # Lista turnos e janelas para a seleção recebida na requisição.
    # Retorna HTML; consulta o banco e prepara a view.
    def index
      @turnos = Turno.includes(:time_frames).order(:inicio, :id).to_a
      @turno = @turnos.find { |item| item.id.to_s == params[:turno_id].to_s } || @turnos.first
      carregar_janelas
    end

    # Cadastra um turno e gera suas janelas.
    # Lê os parâmetros da requisição; retorna redirecionamento e grava no banco.
    def create
      turno = Turnos::ConfiguracaoService.criar(
        atributos: turno_params,
        duracao_intervalo: params[:duracao_intervalo]
      )
      redirect_to admin_turnos_path(turno_id: turno.id), notice: 'Turno cadastrado e janelas geradas.'
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_turnos_path, alert: e.record.errors.full_messages.to_sentence
    rescue ArgumentError => e
      redirect_to admin_turnos_path, alert: e.message
    end

    # Atualiza o turno informado, preservando janelas com inscrições.
    # Lê os parâmetros da requisição; retorna redirecionamento e grava em transação.
    def update
      turno = Turno.find(params[:id])
      atualizar_turno(turno)
      redirecionar_turno(turno.id, notice: 'Configuracao do turno salva.')
    rescue Turnos::ConfiguracaoService::JanelasComInscricoes, ArgumentError => e
      redirecionar_turno(params[:id], alert: e.message)
    rescue ActiveRecord::RecordInvalid => e
      redirecionar_turno(params[:id], alert: e.record.errors.full_messages.to_sentence)
    end

    private

    # Redireciona para o turno de id recebido com a mensagem informada.
    # Retorna a resposta HTTP e define flash; não altera o banco.
    def redirecionar_turno(id, **mensagem)
      redirect_to admin_turnos_path(turno_id: id), **mensagem
    end

    # Prepara as janelas e a duração do turno selecionado.
    # Sem argumentos; retorna a duração e consulta as associações do turno.
    def carregar_janelas
      @janelas = @turno ? @turno.time_frames.sort_by { |janela| [janela.inicio, janela.id] } : []
      @duracao_intervalo = @turno ? Turnos::ConfiguracaoService.duracao_atual(@turno) : 15
    end

    # Atualiza o turno recebido com os parâmetros permitidos da requisição.
    # Retorna Turno ou lança erro; altera o banco pelo serviço de configuração.
    def atualizar_turno(turno)
      Turnos::ConfiguracaoService.atualizar(
        turno: turno, atributos: turno_params,
        duracao_intervalo: params[:duracao_intervalo]
      )
    end

    # Restringe a interface a administradores autenticados.
    # Sem argumentos; retorna nil ou redirecionamento, sem alterar o banco.
    def exigir_administrador
      return if usuario_atual&.administrador?

      redirect_to login_path, alert: 'Acesso restrito a administradores.'
    end

    # Seleciona nome, horários e preço permitidos na requisição.
    # Sem argumentos; retorna parâmetros permitidos, sem acessar o banco.
    def turno_params
      params.require(:turno).permit(:nome, :inicio, :fim, :preco)
    end
  end
end
