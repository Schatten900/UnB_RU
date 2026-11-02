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

  test "tela de login renderiza somente o formulário novo" do
    get login_path

    assert_response :success
    assert_select "main.login-page", count: 1
    assert_select "form.login-form", count: 1
  end

  test "funcionário autentica dentro do horário e acessa configuração" do
    travel_to BRASILIA.local(2026, 10, 30, 12, 0) do
      post login_path, params: { matricula: @funcionario.matricula, senha: "senha-segura" }
    end

    assert_redirected_to ponto_configuracao_path
    assert_equal @funcionario.matricula, session[:usuario_matricula]
  end

  test "estudante autentica e acessa o cardápio" do
    estudante = Usuario.create!(
      matricula: "232040501",
      nome: "Estudante de teste",
      senha: "senha-segura",
      perfil: "estudante",
      turno: @turno,
      saldo: 4.5
    )

    post login_path, params: { matricula: estudante.matricula, senha: "senha-segura" }

    assert_redirected_to cardapio_path
    assert_equal estudante.matricula, session[:usuario_matricula]
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

  test "seleção salva restaurante e catraca na sessão e rejeita identificadores inválidos" do
    restaurante = Restaurante.create!(nome: "RU de teste")
    catraca = restaurante.catracas.create!(piso: 1, modo_acesso: "normal")
    travel_to BRASILIA.local(2026, 10, 30, 12, 0) do
      post login_path, params: { matricula: @funcionario.matricula, senha: "senha-segura" }
    end

    post ponto_configuracao_path, params: { restaurante_id: restaurante.id, catraca_id: catraca.id }
    assert_redirected_to ponto_configuracao_path
    assert_equal restaurante.id, session[:restaurante_id]
    assert_equal catraca.id, session[:catraca_id]

    get ponto_configuracao_path
    assert_response :success
    assert_select ".restaurant-option", text: /RU de teste/
    assert_select ".gate-option", text: /Catraca ##{catraca.id}/

    post ponto_configuracao_path, params: { restaurante_id: restaurante.id, catraca_id: "999999" }
    assert_response :unprocessable_content
    assert_equal restaurante.id, session[:restaurante_id]
    assert_equal catraca.id, session[:catraca_id]

    outro_restaurante = Restaurante.create!(nome: "RU não relacionado")
    outra_catraca = outro_restaurante.catracas.create!(piso: 2, modo_acesso: "fastpass")
    post ponto_configuracao_path, params: { restaurante_id: restaurante.id, catraca_id: outra_catraca.id }
    assert_response :unprocessable_content
  end
end