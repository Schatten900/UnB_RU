
require 'test_helper'

class Api::RecargasControllerTest < ActionController::TestCase
  tests Api::RecargasController

  self.fixture_table_names = []

  setup do
    @usuario, @estado_usuario = criar_usuario_falso
  end

  def criar_usuario_falso
    estado = {
      saldo: 20,
      saldo_pendente: 10
    }

    usuario = Object.new

    usuario.define_singleton_method(:saldo) { estado[:saldo] }
    usuario.define_singleton_method(:saldo_pendente) do
      estado[:saldo_pendente]
    end

    usuario.define_singleton_method(:with_lock) do |&bloco|
      bloco.call
    end

    usuario.define_singleton_method(:increment!) do |atributo, valor|
      estado[atributo] += valor
    end

    [usuario, estado]
  end

  def autenticar_usuario(usuario = @usuario)
    @controller.define_singleton_method(:authenticate_usuario!) {}
    @controller.define_singleton_method(:current_usuario) { usuario }
  end

  def criar_recarga_falsa(pendente: true, valor: 10)
    estado = {
      status: pendente ? 'pendente' : 'concluida',
      atualizada: false
    }

    recarga = Object.new

    recarga.define_singleton_method(:reload) { self }

    recarga.define_singleton_method(:pendente?) do
      estado[:status] == 'pendente'
    end

    recarga.define_singleton_method(:valor) { valor }

    recarga.define_singleton_method(:update!) do |**atributos|
      estado.merge!(atributos)
      estado[:atualizada] = true
    end

    [recarga, estado]
  end

  def configurar_recargas(usuario, recarga, id: '1')
    colecao = Object.new

    colecao.define_singleton_method(:find) do |identificador|
      raise ActiveRecord::RecordNotFound unless identificador.to_s == id

      recarga
    end

    usuario.define_singleton_method(:recargas) { colecao }
  end

  test 'cria uma recarga com sucesso' do
    autenticar_usuario

    recarga_retorno = {
      id: 1,
      valor: '10.0',
      metodo: 'pix',
      status: 'pendente'
    }

    argumentos_recebidos = nil

    servico = Object.new
    servico.define_singleton_method(:call) { recarga_retorno }

    construtor = lambda do |usuario, valor, metodo|
      argumentos_recebidos = [usuario, valor, metodo]
      servico
    end

    Recargas::CriarRecarga.stub(:new, construtor) do
      post :create, params: {
        valor: '10.00',
        metodo: 'pix'
      }
    end

    assert_response :created

    json = response.parsed_body

    assert_equal 'Recarga criada com sucesso', json['mensagem']
    assert_equal 1, json.dig('recarga', 'id')
    assert_equal '10.0', json.dig('recarga', 'valor')
    assert_equal 20, json['saldo']
    assert_equal 10, json['saldo_pendente']

    assert_equal @usuario, argumentos_recebidos[0]
    assert_equal '10.00', argumentos_recebidos[1]
    assert_equal 'pix', argumentos_recebidos[2]
  end

  test 'retorna erro quando o valor da recarga é inválido' do
    autenticar_usuario

    Recargas::CriarRecarga.stub(
      :new,
      ->(*) { raise ArgumentError }
    ) do
      post :create, params: {
        valor: '-10',
        metodo: 'pix'
      }
    end

    assert_response :unprocessable_content

    assert_equal(
      'Por favor, insira um valor de crédito válido',
      response.parsed_body['erro']
    )
  end

  test 'retorna erro quando ocorre uma falha de validação ao criar recarga' do
    autenticar_usuario

    Recargas::CriarRecarga.stub(
      :new,
      ->(*) { raise ActiveRecord::RecordInvalid.new }
    ) do
      post :create, params: {
        valor: '10',
        metodo: 'pix'
      }
    end

    assert_response :unprocessable_content

    assert_equal(
      'Por favor, insira um valor de crédito válido',
      response.parsed_body['erro']
    )
  end

  test 'confirma uma recarga pendente com sucesso' do
    autenticar_usuario

    recarga, estado_recarga = criar_recarga_falsa(
      pendente: true,
      valor: 10
    )

    configurar_recargas(@usuario, recarga)

    post :confirmar, params: { id: 1 }

    assert_response :success

    json = response.parsed_body

    assert_equal 'Pagamento confirmado', json['mensagem']
    assert_equal 30, json['saldo']
    assert_equal 10, json['saldo_pendente']

    assert_equal 30, @estado_usuario[:saldo]
    assert_equal 'concluida', estado_recarga[:status]
    assert estado_recarga[:atualizada]
  end

  test 'não confirma uma recarga que já foi concluída' do
    autenticar_usuario

    recarga, estado_recarga = criar_recarga_falsa(
      pendente: false,
      valor: 10
    )

    configurar_recargas(@usuario, recarga)

    post :confirmar, params: { id: 1 }

    assert_response :unprocessable_content

    assert_equal(
      'Não foi possível confirmar o pagamento',
      response.parsed_body['erro']
    )

    assert_equal 20, @estado_usuario[:saldo]
    assert_equal 'concluida', estado_recarga[:status]
    assert_not estado_recarga[:atualizada]
  end

  test 'retorna erro quando ocorre uma falha de validação na confirmação' do
    autenticar_usuario

    recarga, estado_recarga = criar_recarga_falsa(
      pendente: true,
      valor: 10
    )

    configurar_recargas(@usuario, recarga)

    # Simula uma falha de persistência durante o crédito.
    @usuario.define_singleton_method(:increment!) do |_atributo, _valor|
      raise ActiveRecord::RecordInvalid.new
    end

    post :confirmar, params: { id: 1 }

    assert_response :unprocessable_content

    assert_equal(
      'Não foi possível confirmar o pagamento',
      response.parsed_body['erro']
    )

    assert_equal 20, @estado_usuario[:saldo]
    assert_equal 'pendente', estado_recarga[:status]
  end

  test 'não confirma recarga que não pertence ao usuário atual' do
    autenticar_usuario

    colecao = Object.new

    colecao.define_singleton_method(:find) do |_id|
      raise ActiveRecord::RecordNotFound
    end

    @usuario.define_singleton_method(:recargas) { colecao }

    assert_raises(ActiveRecord::RecordNotFound) do
      post :confirmar, params: { id: 999 }
    end
  end

  test 'utiliza o bloqueio da conta durante a confirmação' do
    autenticar_usuario

    recarga, = criar_recarga_falsa(
      pendente: true,
      valor: 10
    )

    configurar_recargas(@usuario, recarga)

    bloqueio_executado = false

    @usuario.define_singleton_method(:with_lock) do |&bloco|
      bloqueio_executado = true
      bloco.call
    end

    post :confirmar, params: { id: 1 }

    assert_response :success
    assert bloqueio_executado
  end

  test 'recarrega a recarga antes de verificar se está pendente' do
    autenticar_usuario

    recarga, = criar_recarga_falsa(
      pendente: true,
      valor: 10
    )

    recarregada = false

    recarga.define_singleton_method(:reload) do
      recarregada = true
      self
    end

    configurar_recargas(@usuario, recarga)

    post :confirmar, params: { id: 1 }

    assert_response :success
    assert recarregada
  end
end

#AI: GPT WEB
#Prompt: Provided context for the project, asked to generate tests based on the context
