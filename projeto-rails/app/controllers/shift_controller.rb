
module Api
  class ShiftsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_staff

    def index
      shifts = Shift.includes(:shift_intervals)

      render json: shifts.as_json(
        include: :shift_intervals
      )
    end

    def show
      shift = Shift.includes(:shift_intervals).find(params[:id])

      render json: shift.as_json(
        include: :shift_intervals
      )
    end

    def create
      shift = Shift.new(shift_params)

      if shift.save
        Shifts::GenerateIntervals.new(shift).call

        render json: shift.as_json(
          include: :shift_intervals
        ), status: :created
      else
        render json: {
          errors: shift.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    def update
      shift = Shift.find(params[:id])

      if shift.update(shift_params)
        Shifts::GenerateIntervals.new(shift).call

        render json: shift.as_json(
          include: :shift_intervals
        )
      else
        render json: {
          errors: shift.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    private

    def require_staff
      unless current_user.staff?
        render json: {
          error: "Você não tem permissões para esta funcionalidade"
        }, status: :forbidden
      end
    end

    def shift_params
      params.require(:shift).permit(
        :start_time,
        :end_time,
        :interval_duration
      )
    end
  end
end



#AI: GPT desktop, no think
#Prompt and strategy: First, we warmed GPT up by asking for file structure given the proposed feature, then we asked for a code with our project's specs, this was consolidated with other .rb