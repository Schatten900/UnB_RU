
##
# Serviço responsável por gerar notificações para os usuários
# inscritos no sorteio do FastPass.
#
# Analisa o resultado da inscrição, define a mensagem correspondente
# e registra a notificação no banco de dados.
#
class NotificacaoService

  ##
  # Cria uma notificação de acordo com o resultado de uma inscrição
  # FastPass e atualiza seu status de notificação.
  #
  # A operação utiliza uma transação para garantir que a criação
  # da notificação e a atualização da inscrição sejam realizadas
  # conjuntamente.
  #
  # @param inscricao [InscricaoFastpass] Inscrição do usuário no
  #   sorteio FastPass, contendo seu resultado e seus dados.
  #
  # @return [Boolean] Retorna +true+ quando a notificação é criada
  #   e a inscrição atualizada com sucesso. Retorna +false+ quando
  #   o resultado da inscrição não corresponde a nenhum resultado
  #   reconhecido pelo serviço.
  #
  # @raise [ActiveRecord::RecordInvalid] Caso a criação da notificação
  #   ou a atualização da inscrição falhe durante a transação.
  #
  # Efeito colateral: Insere um registro na tabela de notificações
  # e atualiza os campos status_notificacao e notificada_em da inscrição.
  def self.call(inscricao:)
    mensagem = case inscricao.resultado
               when InscricaoFastpass::RESULTADO_GANHOU
                 "Parabéns! Você ganhou o FastPass."
               when InscricaoFastpass::RESULTADO_NAO_GANHOU
                 "Você não foi contemplado no sorteio de FastPass."
               else
                 return false
               end

    Notificacao.transaction do
      Notificacao.create!(
        usuario_matricula: inscricao.usuario_matricula,
        mensagem: mensagem
      )

      inscricao.update!(
        status_notificacao: "entregue",
        notificada_em: Time.current
      )
    end

    true
  end
end
