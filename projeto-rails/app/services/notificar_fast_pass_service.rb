class NotificacaoService
  def self.call(inscricao:)
    mensagem = case inscricao.resultado
               when "contemplada"
                 "Parabéns! Você ganhou o FastPass."
               when "nao contemplada"
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
