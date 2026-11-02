
module Api
  class RegistrationsController < ApplicationController
    def create
      student_id = params[:student_id].to_s

      unless student_id.match?(/\A\d+\z/) &&
             !student_id.start_with?("999")
        return render json: {
          error: "Você deve fornecer um número de estudante válido"
        }, status: :unprocessable_entity
      end

      user = User.new(user_params)

      if user.save
        user.create_account!(
          balance: 0,
          pending_balance: 0
        )

        render json: {
          message: "Conta criada com sucesso",
          user: {
            id: user.id,
            student_id: user.student_id
          }
        }, status: :created
      else
        render json: {
          errors: user.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.permit(
        :student_id,
        :email,
        :password,
        :password_confirmation
      )
    end
  end
end



#AI: GPT desktop, no think
#Prompt and strategy: First, we warmed GPT up by asking for file structure given the proposed feature, then we asked for a code with our project's specs, this was consolidated with other .rb