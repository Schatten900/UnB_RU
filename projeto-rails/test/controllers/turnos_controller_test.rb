
require 'test_helper'

class Api::TurnosControllerTest < ActionController::TestCase
  tests Api::TurnosController

  self.fixture_table_names = []

  setup do
    @turno = Turno.create!(
      nome: 'Almoço',
      inicio: '11:00',
      fim: '14:00',
      preco: 4.50
    )
  end

  # Simula a autenticação e define o perfil do usuário atual.
  def autenticar_com(funcionario: false, administrador: false)
    usuario = Object.new

    usuario.define_singleton_method(:funcionario?) { funcionario }
    usuario.define_singleton_method(:administrador?) { administrador }

    @controller.define_singleton_method(:authenticate_usuario!) {}
    @controller.define_singleton_method(:current_usuario) { usuario }

    usuario
  end

  # Intercepta o serviço responsável pela geração dos intervalos.
  def com_gerador_timeframe
    chamadas = {
      construido: false,
      executado: false,
      turno: nil,
      duracao_intervalo: nil
    }

    gerador = Object.new

    gerador.define_singleton_method(:call) do
      chamadas[:executado] = true
    end

    construtor = lambda do |turno, duracao_intervalo|
      chamadas[:construido] = true
      chamadas[:turno] = turno
      chamadas[:duracao_intervalo] = duracao_intervalo

      gerador
    end

    Turnos::GerarTimeframe.stub(:new, construtor) do
      yield chamadas
    end
  end

  def parametros_turno
    {
      nome: 'Jantar',
      inicio: '18:00',
      fim: '21:00',
      preco: 5.50
    }
  end

  test 'lista todos os turnos para funcionário' do
    autenticar_com(funcionario: true)

    get :index

    assert_response :success

    json = response.parsed_body

    assert_kind_of Array, json
    assert_equal 1, json.size

    turno = json.first

    assert_equal @turno.id, turno['id']
    assert_equal 'Almoço', turno['nome']
    assert_equal '11:00', turno['inicio']
    assert_equal '14:00', turno['fim']

    assert turno.key?('time_frames')
    assert_kind_of Array, turno['time_frames']
  end

  test 'lista todos os turnos para administrador' do
    autenticar_com(administrador: true)

    get :index

    assert_response :success

    json = response.parsed_body

    assert_kind_of Array, json
    assert_equal 1, json.size
  end

  test 'exibe um turno específico com seus intervalos de horário' do
    autenticar_com(funcionario: true)

    get :show, params: { id: @turno.id }

    assert_response :success

    json = response.parsed_body

    assert_equal @turno.id, json['id']
    assert_equal 'Almoço', json['nome']
    assert_equal '11:00', json['inicio']
    assert_equal '14:00', json['fim']

    assert json.key?('time_frames')
    assert_kind_of Array, json['time_frames']
  end

  test 'cria um turno e gera seus intervalos de horário' do
    autenticar_com(administrador: true)

    com_gerador_timeframe do |chamadas|
      assert_difference('Turno.count', 1) do
        post :create, params: {
          turno: parametros_turno,
          duracao_intervalo: '30'
        }
      end

      assert_response :created

      json = response.parsed_body

      assert_equal 'Jantar', json['nome']
      assert_equal '18:00', json['inicio']
      assert_equal '21:00', json['fim']

      assert json.key?('time_frames')

      assert chamadas[:construido]
      assert chamadas[:executado]
      assert_equal json['id'], chamadas[:turno].id
      assert_equal '30', chamadas[:duracao_intervalo]
    end
  end

  test 'não cria turno quando os parâmetros são inválidos' do
    autenticar_com(administrador: true)

    com_gerador_timeframe do |chamadas|
      assert_no_difference('Turno.count') do
        post :create, params: {
          turno: {
            nome: '',
            inicio: '11:00',
            fim: '14:00',
            preco: 4.50
          },
          duracao_intervalo: '30'
        }
      end

      assert_response :unprocessable_content

      json = response.parsed_body

      assert json['erros'].present?
      assert_kind_of Array, json['erros']

      assert_not chamadas[:construido]
      assert_not chamadas[:executado]
    end
  end

  test 'atualiza um turno e regenera seus intervalos de horário' do
    autenticar_com(funcionario: true)

    com_gerador_timeframe do |chamadas|
      patch :update, params: {
        id: @turno.id,
        turno: {
          nome: 'Jantar',
          inicio: '18:00',
          fim: '21:00',
          preco: 5.50
        },
        duracao_intervalo: '20'
      }

      assert_response :success

      json = response.parsed_body

      assert_equal @turno.id, json['id']
      assert_equal 'Jantar', json['nome']
      assert_equal '18:00', json['inicio']
      assert_equal '21:00', json['fim']

      assert json.key?('time_frames')

      @turno.reload

      assert_equal 'Jantar', @turno.nome
      assert_equal 5.50.to_d, @turno.preco

      assert chamadas[:construido]
      assert chamadas[:executado]
      assert_equal @turno.id, chamadas[:turno].id
      assert_equal '20', chamadas[:duracao_intervalo]
    end
  end

  test 'não atualiza turno quando os parâmetros são inválidos' do
    autenticar_com(administrador: true)

    com_gerador_timeframe do |chamadas|
      patch :update, params: {
        id: @turno.id,
        turno: {
          nome: '',
          inicio: '11:00',
          fim: '14:00',
          preco: 4.50
        },
        duracao_intervalo: '30'
      }

      assert_response :unprocessable_content

      json = response.parsed_body

      assert json['erros'].present?
      assert_kind_of Array, json['erros']

      assert_not chamadas[:construido]
      assert_not chamadas[:executado]

      @turno.reload

      assert_equal 'Almoço', @turno.nome
    end
  end

  test 'retorna forbidden quando estudante tenta acessar os turnos' do
    autenticar_com

    get :index

    assert_response :forbidden

    json = response.parsed_body

    assert_equal(
      'Você não tem permissões para esta funcionalidade',
      json['erro']
    )
  end

  test 'retorna forbidden quando estudante tenta consultar um turno específico' do
    autenticar_com

    get :show, params: { id: @turno.id }

    assert_response :forbidden

    assert_equal(
      'Você não tem permissões para esta funcionalidade',
      response.parsed_body['erro']
    )
  end

  test 'retorna forbidden quando estudante tenta criar um turno' do
    autenticar_com

    assert_no_difference('Turno.count') do
      post :create, params: {
        turno: parametros_turno,
        duracao_intervalo: '30'
      }
    end

    assert_response :forbidden

    assert_equal(
      'Você não tem permissões para esta funcionalidade',
      response.parsed_body['erro']
    )
  end

  test 'retorna forbidden quando estudante tenta atualizar um turno' do
    autenticar_com

    patch :update, params: {
      id: @turno.id,
      turno: parametros_turno,
      duracao_intervalo: '30'
    }

    assert_response :forbidden

    assert_equal(
      'Você não tem permissões para esta funcionalidade',
      response.parsed_body['erro']
    )

    @turno.reload

    assert_equal 'Almoço', @turno.nome
  end
end

# AI: GPT desktop, no think
# Prompt and strategy: First, we warmed GPT up by asking for file structure given the proposed feature, then we asked for a code with our project's specs, this was consolidated with other .rb files.
#AI: GPT web #Prompt: Agora este, por favor — criar testes para Api::TurnosController.
