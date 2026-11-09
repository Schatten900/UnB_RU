
module Api
  class TurnosController < ApplicationController
    before_action :authenticate_usuario!
    before_action :require_funcionario

    def index
      turnos = Turno.includes(:time_frames)

      render json: turnos.as_json(
        include: :time_frames
      )
    end

    def show
      turno = Turno.includes(:time_frames).find(params[:id])

      render json: turno.as_json(
        include: :time_frames
      )
    end

    def create
      turno = Turno.new(turno_params)

      if turno.save
        Turnos::GerarTimeframe.new(
          turno,
          params[:duracao_intervalo]
        ).call

        render json: turno.as_json(
          include: :time_frames
        ), status: :created
      else
        render json: {
          erros: turno.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    def update
      turno = Turno.find(params[:id])

      if turno.update(turno_params)
        Turnos::GerarTimeframe.new(
          turno,
          params[:duracao_intervalo]
        ).call

        render json: turno.as_json(
          include: :time_frames
        )
      else
        render json: {
          erros: turno.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    private

    def require_funcionario
      unless current_usuario.funcionario? || current_usuario.administrador?
        render json: {
          erro: "Você não tem permissões para esta funcionalidade"
        }, status: :forbidden
      end
    end

    def turno_params
      params.require(:turno).permit(
        :nome,
        :inicio,
        :fim,
        :preco
      )
    end
  end
end
#AI: GPT desktop, no think
#Prompt and strategy: First, we warmed GPT up by asking for file structure given the proposed feature, then we asked for a code with our project's specs, this was consolidated with other .rb
