
require 'test_helper'

class Api::CadastrosControllerTest < ActionController::TestCase
  tests Api::CadastrosController

  self.fixture_table_names = []

  def parametros_cadastro
    {
      matricula: '232040501',
      nome: 'Estudante de teste',
      senha: 'senha-segura'
    }
  end

  test 'cria uma conta de estudante com dados válidos' do
    assert_difference('Usuario.count', 1) do
      post :create, params: parametros_cadastro
    end

    assert_response :created

    json = response.parsed_body

    assert_equal 'Conta criada com sucesso', json['mensagem']

    usuario_json = json['usuario']

    assert_equal '232040501', usuario_json['matricula']
    assert_equal 'Estudante de teste', usuario_json['nome']
    assert_equal 'estudante', usuario_json['perfil']
    assert_equal 0.to_d, BigDecimal(usuario_json['saldo'].to_s)

    usuario = Usuario.find_by!(matricula: '232040501')

    assert_equal '232040501', usuario.matricula
    assert_equal 'Estudante de teste', usuario.nome
    assert_equal 'estudante', usuario.perfil
    assert_equal 0.to_d, usuario.saldo
  end

  test 'retorna erro quando a matrícula não é informada' do
    assert_no_difference('Usuario.count') do
      post :create, params: {
        nome: 'Estudante de teste',
        senha: 'senha-segura'
      }
    end

    assert_response :unprocessable_content

    assert_equal(
      'Você deve fornecer um número de estudante válido',
      response.parsed_body['erro']
    )
  end

  test 'retorna erro quando a matrícula possui menos de nove dígitos' do
    assert_no_difference('Usuario.count') do
      post :create, params: {
        matricula: '12345678',
        nome: 'Estudante de teste',
        senha: 'senha-segura'
      }
    end

    assert_response :unprocessable_content

    assert_equal(
      'Você deve fornecer um número de estudante válido',
      response.parsed_body['erro']
    )
  end

  test 'retorna erro quando a matrícula possui mais de nove dígitos' do
    assert_no_difference('Usuario.count') do
      post :create, params: {
        matricula: '1234567890',
        nome: 'Estudante de teste',
        senha: 'senha-segura'
      }
    end

    assert_response :unprocessable_content

    assert_equal(
      'Você deve fornecer um número de estudante válido',
      response.parsed_body['erro']
    )
  end

  test 'retorna erro quando a matrícula contém letras ou caracteres especiais' do
    matriculas_invalidas = [
      '12345A789',
      '123-45678',
      '123 45678',
      '1234567@9'
    ]

    matriculas_invalidas.each do |matricula|
      assert_no_difference('Usuario.count') do
        post :create, params: {
          matricula: matricula,
          nome: 'Estudante de teste',
          senha: 'senha-segura'
        }
      end

      assert_response :unprocessable_content

      assert_equal(
        'Você deve fornecer um número de estudante válido',
        response.parsed_body['erro']
      )
    end
  end

  test 'não instancia usuário quando a matrícula é inválida' do
    Usuario.stub(
      :new,
      ->(*_args, **_kwargs) {
        flunk 'Usuario.new não deveria ser chamado com matrícula inválida'
      }
    ) do
      post :create, params: {
        matricula: '12345678',
        nome: 'Estudante de teste',
        senha: 'senha-segura'
      }
    end

    assert_response :unprocessable_content
  end

  test 'aceita matrícula de nove dígitos iniciada por 999' do
    parametros = parametros_cadastro.merge(
      matricula: '999040501'
    )

    assert_difference('Usuario.count', 1) do
      post :create, params: parametros
    end

    assert_response :created

    assert_equal(
      '999040501',
      response.parsed_body.dig('usuario', 'matricula')
    )
  end

  test 'retorna erros quando o usuário não consegue ser salvo' do
    erros = Object.new
    erros.define_singleton_method(:full_messages) do
      ['Nome não pode ficar em branco']
    end

    usuario_falso = Object.new
    usuario_falso.define_singleton_method(:save) { false }
    usuario_falso.define_singleton_method(:errors) { erros }

    atributos_recebidos = nil

    construtor = lambda do |*args, **kwargs|
      atributos_recebidos = kwargs.presence || args.first
      usuario_falso
    end

    Usuario.stub(:new, construtor) do
      post :create, params: {
        matricula: '232040501',
        nome: '',
        senha: 'senha-segura'
      }
    end

    assert_response :unprocessable_content

    json = response.parsed_body

    assert_equal(
      ['Nome não pode ficar em branco'],
      json['erros']
    )

    assert_equal '232040501', atributos_recebidos[:matricula]
    assert_equal '', atributos_recebidos[:nome]
    assert_equal 'senha-segura', atributos_recebidos[:senha]
    assert_equal 'estudante', atributos_recebidos[:perfil]
    assert_equal 0, atributos_recebidos[:saldo]
  end

  test 'limpa a sessão anterior após criar uma conta' do
    session[:usuario_matricula] = '111111111'
    session[:outra_informacao] = 'informacao_antiga'

    post :create, params: parametros_cadastro

    assert_response :created

    assert_equal '232040501', session[:usuario_matricula]
    assert_nil session[:outra_informacao]
  end

  test 'não altera a sessão quando a matrícula é inválida' do
    session[:usuario_matricula] = '111111111'
    session[:outra_informacao] = 'informacao_antiga'

    post :create, params: {
      matricula: '123',
      nome: 'Estudante de teste',
      senha: 'senha-segura'
    }

    assert_response :unprocessable_content

    assert_equal '111111111', session[:usuario_matricula]
    assert_equal 'informacao_antiga', session[:outra_informacao]
  end

  test 'retorna somente os dados públicos do usuário na resposta' do
    post :create, params: parametros_cadastro

    assert_response :created

    usuario_json = response.parsed_body['usuario']

    assert_equal(
      %w[matricula nome perfil saldo].sort,
      usuario_json.keys.sort
    )

    assert_not usuario_json.key?('senha')
    assert_not usuario_json.key?('password_digest')
  end
end

#AI: GPT web #Prompt: Agora, baseado no contexto provido, faça o teste do CadastrosController
