
module Api
  class ReportsController < ApplicationController
    before_action :authenticate_user!

    def global_operations
      unless current_user.staff?
        return render json: {
          error: "Você não tem permissões para esta funcionalidade"
        }, status: :forbidden
      end

      pdf = Reports::GlobalOperationsPdf.generate

      send_data pdf,
        filename: "relatorio_operacoes.pdf",
        type: "application/pdf",
        disposition: "attachment"
    end
  end
end



#AI: GPT desktop, no think
#Prompt and strategy: First, we warmed GPT up by asking for file structure given the proposed feature, then we asked for a code with our project's specs, this was consolidated with other .rb