#cadastros_controller.rb
module Api
  class CadastrosController < ApplicationController
    def create
      matricula = params[:matricula].to_s

      unless matricula.match?(/\A\d{9}\z/) &&
             !matricula.start_with?("999")
        return render json: {
          erro: "Você deve fornecer um número de estudante válido"
        }, status: :unprocessable_entity
      end

      usuario = Usuario.new(
        matricula: matricula,
        nome: params[:nome],
        senha: params[:senha],
        perfil: "estudante",
        saldo: 0
      )

      if usuario.save
        reset_session
        session[:usuario_matricula] = usuario.matricula

        render json: {
          mensagem: "Conta criada com sucesso",
          usuario: {
            matricula: usuario.matricula,
            nome: usuario.nome,
            perfil: usuario.perfil,
            saldo: usuario.saldo
          }
        }, status: :created
      else
        render json: {
          erros: usuario.errors.full_messages
        }, status: :unprocessable_entity
      end
    end
  end
end
