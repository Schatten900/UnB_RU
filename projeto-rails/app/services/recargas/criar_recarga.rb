
module Recargas
  class CriarRecarga
    def initialize(usuario, valor, metodo)
      @usuario = usuario
      @valor = BigDecimal(valor.to_s)
      @metodo = metodo
    end

    def call
      raise ArgumentError unless @valor.positive?

      raise ArgumentError unless
        %w[pix cartao_credito].include?(@metodo)

      recarga = nil

      @usuario.with_lock do
        recarga = @usuario.recargas.create!(
          valor: @valor,
          metodo: @metodo,
          status: :pendente,
          data_hora: Time.current
        )

        if @metodo == "pix"
          recarga.update!(
            codigo_pix: "PIX-MOCK-#{recarga.id}-#{SecureRandom.hex(4)}"
          )
        else
          recarga.update!(status: :concluida)

          @usuario.increment!(:saldo, @valor)
        end
      end

      recarga
    end
  end
end
#AI: GPT desktop, no think
#Prompt and strategy: First, we warmed GPT up by asking for file structure given the proposed feature, then we asked for a code with our project's specs, this was consolidated with other .rb
