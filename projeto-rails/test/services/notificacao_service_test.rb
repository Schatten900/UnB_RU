
require "test_helper"

class NotificacaoServiceTest < ActiveSupport::TestCase
  test "não cria notificação quando a inscrição não tem resultado" do
    inscricao = InscricaoFastPass.new(
      resultado: nil,
      status_notificacao: "pendente"
    )

    resultado = NotificacaoService.call(inscricao: inscricao)

    assert_equal false, resultado
    assert_equal 0, Notificacao.count
  end
end
