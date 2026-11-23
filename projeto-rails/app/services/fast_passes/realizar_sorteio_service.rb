module FastPasses
  class RealizarSorteioService
    def self.call(sorteio:)
      sorteio.with_lock do
        unless sorteio.status == "aberto" && sorteio.data >= Date.current
          raise ArgumentError, "Somente sorteios abertos de hoje ou de datas futuras podem ser executados."
        end
        validar_cotas!(sorteio)
        inscricoes = sorteio.inscricoes_fastpass.includes(:catraca).to_a
        if inscricoes.any? { |inscricao| inscricao.resultado.present? || inscricao.catraca.nil? }
          raise ArgumentError, "Existem inscrições com resultado definido ou sem restaurante atribuído. Revise este sorteio antes de executá-lo."
        end

        inscricoes.group_by { |inscricao| [inscricao.catraca.restaurante_id.to_s, inscricao.time_frame_id.to_s] }
          .each do |(restaurante_id, janela_id), participantes|
            quantidade = sorteio.cotas.dig(restaurante_id, janela_id) || 0
            vencedores = participantes.sample([quantidade, participantes.size].min).map(&:id)
            participantes.each do |inscricao|
              resultado = vencedores.include?(inscricao.id) ? InscricaoFastpass::RESULTADO_GANHOU : InscricaoFastpass::RESULTADO_NAO_GANHOU
              inscricao.update!(resultado: resultado, status_notificacao: "pendente", notificada_em: nil)
            end
          end
        sorteio.update!(status: "concluido")
      end
      sorteio
    end

    def self.validar_cotas!(sorteio)
      raise ArgumentError, "Configure as cotas antes de executar o sorteio." if sorteio.cotas.empty?
      restaurantes = Restaurante.pluck(:id).map(&:to_s)
      janelas = TimeFrame.pluck(:id).map(&:to_s)
      sorteio.cotas.each do |restaurante_id, cotas|
        unless restaurantes.include?(restaurante_id) && cotas.is_a?(Hash) && cotas.present? &&
            cotas.all? { |janela_id, valor| janelas.include?(janela_id) && valor.is_a?(Integer) && valor >= 0 }
          raise ArgumentError, "As janelas ou restaurantes foram alterados. Revise e aplique as cotas novamente."
        end
      end
    end
    private_class_method :validar_cotas!
  end
end
