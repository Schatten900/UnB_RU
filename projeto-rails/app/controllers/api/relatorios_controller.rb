
module Api
  class RelatoriosController < ApplicationController
    before_action :authenticate_usuario!

    def global_operations
      unless current_usuario.administrador?
        return render json: {
          erro: "Você não tem permissões para esta funcionalidade"
        }, status: :forbidden
      end

      pdf = Relatorios::RelatorioOperacoesPdf.generate

      send_data pdf,
        filename: "relatorio_operacoes.pdf",
        type: "application/pdf",
        disposition: "attachment"
    end
  end
end
#AI: GPT desktop, no think
#Prompt and strategy: First, we warmed GPT up by asking for file structure given the proposed feature, then we asked for a code with our project's specs, this was consolidated with other .rb
