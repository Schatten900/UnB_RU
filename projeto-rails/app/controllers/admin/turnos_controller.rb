module Admin
  # Intencionalmente independente de Admin::BaseController (US13 ainda em outro PR).
  class TurnosController < ApplicationController
    before_action :exigir_administrador

    def index
      @turnos = Turno.includes(:time_frames).order(:inicio, :id).to_a
      @turno = @turnos.find { |item| item.id.to_s == params[:turno_id].to_s } || @turnos.first
      @janelas = @turno ? @turno.time_frames.sort_by { |janela| [janela.inicio, janela.id] } : []
      @duracao_intervalo = @turno ? Turnos::ConfiguracaoService.duracao_atual(@turno) : 15
    end

    def create
      turno = Turnos::ConfiguracaoService.criar(
        atributos: turno_params,
        duracao_intervalo: params[:duracao_intervalo]
      )
      redirect_to admin_turnos_path(turno_id: turno.id), notice: "Turno cadastrado e janelas geradas."
    rescue ActiveRecord::RecordInvalid => erro
      redirect_to admin_turnos_path, alert: erro.record.errors.full_messages.to_sentence
    rescue ArgumentError => erro
      redirect_to admin_turnos_path, alert: erro.message
    end

    def update
      turno = Turno.find(params[:id])
      Turnos::ConfiguracaoService.atualizar(
        turno: turno,
        atributos: turno_params,
        duracao_intervalo: params[:duracao_intervalo]
      )
      redirect_to admin_turnos_path(turno_id: turno.id), notice: "Configuracao do turno salva."
    rescue Turnos::ConfiguracaoService::JanelasComInscricoes, ArgumentError => erro
      redirect_to admin_turnos_path(turno_id: params[:id]), alert: erro.message
    rescue ActiveRecord::RecordInvalid => erro
      redirect_to admin_turnos_path(turno_id: params[:id]), alert: erro.record.errors.full_messages.to_sentence
    end

    private

    def exigir_administrador
      return if usuario_atual&.administrador?

      redirect_to login_path, alert: "Acesso restrito a administradores."
    end

    def turno_params
      params.require(:turno).permit(:nome, :inicio, :fim, :preco)
    end
  end
end
