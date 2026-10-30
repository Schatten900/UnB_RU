require "test_helper"

class AutenticacaoControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []
  BRASILIA = Time.find_zone!("America/Sao_Paulo")

  setup do
    @turno = Turno.create!(nome: "Expediente", inicio: "09:00", fim: "17:00", preco: 0)
    @funcionario = Usuario.create!(
      matricula: "999123456",
      nome: "Funcionário de teste",
      senha: "senha-segura",
      perfil: "funcionario",
      turno: @turno,
      saldo: 0
    )
  end

  test "funcionário autentica dentro do horário e acessa configuração" do
    travel_to BRASILIA.local(2026, 10, 30, 12, 0) do
      post login_path, params: { matricula: @funcionario.matricula, senha: "senha-segura" }
    end

    assert_redirected_to ponto_configuracao_path
    assert_equal @funcionario.matricula, session[:usuario_matricula]
  end

  test "funcionário não autentica fora do horário permitido" do
    travel_to BRASILIA.local(2026, 10, 30, 18, 0) do
      post login_path, params: { matricula: @funcionario.matricula, senha: "senha-segura" }
    end

    assert_response :unauthorized
    assert_nil session[:usuario_matricula]
  end

  test "funcionário autentica às 19:41 no horário local de Brasília" do
    turno_noturno = Turno.create!(nome: "Noturno", inicio: "17:00", fim: "20:00", preco: 4.50)
    @funcionario.update!(turno: turno_noturno)

    travel_to BRASILIA.local(2026, 10, 30, 19, 41) do
      post login_path, params: { matricula: @funcionario.matricula, senha: "senha-segura" }
    end

    assert_redirected_to ponto_configuracao_path
    assert_equal @funcionario.matricula, session[:usuario_matricula]
  end

  test "senha inválida não cria sessão" do
    post login_path, params: { matricula: @funcionario.matricula, senha: "incorreta" }

    assert_response :unauthorized
    assert_nil session[:usuario_matricula]
  end

  test "configuração exige funcionário autenticado" do
    get ponto_configuracao_path

    assert_redirected_to login_path
    assert_nil session[:usuario_matricula]
  end

  test "seleção salva restaurante na sessão e rejeita identificador inválido" do
    restaurante = Restaurante.create!(nome: "RU de teste")
    travel_to BRASILIA.local(2026, 10, 30, 12, 0) do
      post login_path, params: { matricula: @funcionario.matricula, senha: "senha-segura" }
    end

    post ponto_configuracao_path, params: { restaurante_id: restaurante.id }
    assert_redirected_to ponto_configuracao_path
    assert_equal restaurante.id, session[:restaurante_id]

    post ponto_configuracao_path, params: { restaurante_id: "999999" }
    assert_response :unprocessable_content
    assert_equal restaurante.id, session[:restaurante_id]
  end
end