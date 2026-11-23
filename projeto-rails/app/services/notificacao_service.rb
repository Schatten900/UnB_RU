class NotificacaoService
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