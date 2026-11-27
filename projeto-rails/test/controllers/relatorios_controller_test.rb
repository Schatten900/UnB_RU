
require 'test_helper'

class RelatoriosControllerTest < ActionController::TestCase
  tests RelatoriosController

  # Simula a coleção retornada pelo ActiveRecord.
  class ColecaoFalsa
    def initialize(registros = [])
      @registros = registros
    end

    def order(_coluna)
      @registros
    end
  end

  # Simula o resultado de uma consulta COUNT.
  class ContagemFalsa
    def initialize(valor)
      @valor = valor
    end

    def count
      @valor
    end
  end

  # Simula o encadeamento where.not do ActiveRecord.
  class ConsultaFalsa
    def initialize(relacao)
      @relacao = relacao
    end

    define_method(:not) do |condicoes|
      if condicoes.key?(:passagem_em)
        @relacao
      elsif condicoes.key?(:inscricao_fastpass_id)
        ContagemFalsa.new(@relacao.fastpass_count)
      else
        raise ArgumentError, "Condição não simulada: #{condicoes.inspect}"
      end
    end
  end

  # Simula a relação de acessos concluídos e seus agrupamentos.
  class RelacaoAcessosFalsa
    attr_reader :fastpass_count

    def initialize(
      total:,
      fastpass_count:,
      arrecadacao:,
      data_inicio:,
      restaurantes: [],
      turnos: []
    )
      @total = total
      @fastpass_count = fastpass_count
      @arrecadacao = arrecadacao
      @data_inicio = data_inicio
      @restaurantes = restaurantes
      @turnos = turnos
    end

    def where
      ConsultaFalsa.new(self)
    end

    def minimum(_coluna)
      @data_inicio
    end

    def count
      @total
    end

    def sum(_coluna)
      @arrecadacao
    end

    def joins(_associacao)
      self
    end

    def group(agrupamento)
      @agrupamento = agrupamento
      self
    end

    def pluck(*_colunas)
      case @agrupamento
      when 'catracas.restaurante_id'
        @restaurantes
      when :turno_id
        @turnos
      else
        raise ArgumentError, "Agrupamento não simulado: #{@agrupamento.inspect}"
      end
    end
  end

  setup do
    @data_inicio = Time.zone.local(2026, 10, 1, 11, 0)
  end

  # Substitui somente a autenticação e o usuário atual.
  # Assim os testes concentram-se nas regras deste controller.
  def autenticar_com(administrador:)
    usuario = Object.new
    usuario.define_singleton_method(:administrador?) { administrador }

    @controller.define_singleton_method(:authenticate_usuario!) {}
    @controller.define_singleton_method(:current_usuario) { usuario }

    usuario
  end

  def executar_relatorio(relacao, total_catracas: 4)
    autenticar_com(administrador: true)

    Acesso.stub(:where, ConsultaFalsa.new(relacao)) do
      Restaurante.stub(
        :includes,
        ColecaoFalsa.new([:restaurante_teste])
      ) do
        Turno.stub(:order, [:turno_teste]) do
          Catraca.stub(:count, total_catracas) do
            get :global
          end
        end
      end
    end
  end

  test 'redireciona usuário que não é administrador' do
    autenticar_com(administrador: false)

    get :global

    assert_response :redirect
    assert_redirected_to root_path
    assert_equal(
      'Acesso restrito a administradores.',
      flash[:alert]
    )
  end

  test 'redireciona quando não existe usuário administrador autenticado' do
    # Simula uma sessão sem usuário atual.
    @controller.define_singleton_method(:authenticate_usuario!) {}
    @controller.define_singleton_method(:current_usuario) { nil }

    get :global

    assert_response :redirect
    assert_redirected_to root_path
    assert_equal(
      'Acesso restrito a administradores.',
      flash[:alert]
    )
  end

  test 'exibe indicadores zerados quando não existem acessos concluídos' do
    relacao = RelacaoAcessosFalsa.new(
      total: 0,
      fastpass_count: 0,
      arrecadacao: 0.to_d,
      data_inicio: nil,
      restaurantes: [],
      turnos: []
    )

    executar_relatorio(relacao, total_catracas: 3)

    assert_response :success

    assert_equal Date.current,
                 @controller.instance_variable_get(:@data_hoje)

    assert_nil @controller.instance_variable_get(:@data_inicio_operacao)

    assert_equal 0, @controller.instance_variable_get(:@total_acessos)
    assert_equal 0, @controller.instance_variable_get(:@total_fastpass)
    assert_equal 0, @controller.instance_variable_get(:@total_comum)
    assert_equal 0, @controller.instance_variable_get(:@ticket_medio)
    assert_equal 0.to_d, @controller.instance_variable_get(:@arrecadacao_global)
    assert_equal 3, @controller.instance_variable_get(:@total_catracas)

    assert_equal({}, @controller.instance_variable_get(:@estatisticas_restaurantes))
    assert_equal({}, @controller.instance_variable_get(:@estatisticas_turnos))
  end

  test 'calcula corretamente os indicadores globais com acessos concluídos' do
    relacao = RelacaoAcessosFalsa.new(
      total: 5,
      fastpass_count: 2,
      arrecadacao: 45.to_d,
      data_inicio: @data_inicio,
      restaurantes: [],
      turnos: []
    )

    executar_relatorio(relacao, total_catracas: 6)

    assert_response :success

    assert_equal 5, @controller.instance_variable_get(:@total_acessos)
    assert_equal 2, @controller.instance_variable_get(:@total_fastpass)
    assert_equal 3, @controller.instance_variable_get(:@total_comum)

    assert_equal 45.to_d, @controller.instance_variable_get(:@arrecadacao_global)
    assert_equal 9.to_d, @controller.instance_variable_get(:@ticket_medio)

    assert_equal @data_inicio,
                 @controller.instance_variable_get(:@data_inicio_operacao)

    assert_equal 6, @controller.instance_variable_get(:@total_catracas)
  end

  test 'calcula corretamente as estatísticas agrupadas por restaurante' do
    estatisticas = [
      [10, 3, 2, 27.to_d],
      [20, 2, 0, 18.to_d]
    ]

    relacao = RelacaoAcessosFalsa.new(
      total: 5,
      fastpass_count: 2,
      arrecadacao: 45.to_d,
      data_inicio: @data_inicio,
      restaurantes: estatisticas,
      turnos: []
    )

    executar_relatorio(relacao)

    resultado = @controller.instance_variable_get(:@estatisticas_restaurantes)

    assert_equal(
      {
        10 => {
          acessos: 3,
          fastpass: 2,
          arrecadacao: 27.to_d
        },
        20 => {
          acessos: 2,
          fastpass: 0,
          arrecadacao: 18.to_d
        }
      },
      resultado
    )
  end

  test 'calcula corretamente as estatísticas agrupadas por turno' do
    estatisticas = [
      [1, 3, 27.to_d],
      [2, 2, 18.to_d]
    ]

    relacao = RelacaoAcessosFalsa.new(
      total: 5,
      fastpass_count: 2,
      arrecadacao: 45.to_d,
      data_inicio: @data_inicio,
      restaurantes: [],
      turnos: estatisticas
    )

    executar_relatorio(relacao)

    resultado = @controller.instance_variable_get(:@estatisticas_turnos)

    assert_equal(
      {
        1 => {
          acessos: 3,
          arrecadacao: 27.to_d
        },
        2 => {
          acessos: 2,
          arrecadacao: 18.to_d
        }
      },
      resultado
    )
  end

  test 'calcula as estatísticas de restaurantes e turnos na mesma execução' do
    relacao = RelacaoAcessosFalsa.new(
      total: 4,
      fastpass_count: 1,
      arrecadacao: 32.to_d,
      data_inicio: @data_inicio,
      restaurantes: [
        [10, 2, 1, 16.to_d],
        [20, 2, 0, 16.to_d]
      ],
      turnos: [
        [1, 3, 24.to_d],
        [2, 1, 8.to_d]
      ]
    )

    executar_relatorio(relacao)

    restaurantes = @controller.instance_variable_get(:@estatisticas_restaurantes)
    turnos = @controller.instance_variable_get(:@estatisticas_turnos)

    assert_equal 2, restaurantes.size
    assert_equal 2, turnos.size

    assert_equal 4, @controller.instance_variable_get(:@total_acessos)
    assert_equal 1, @controller.instance_variable_get(:@total_fastpass)
    assert_equal 3, @controller.instance_variable_get(:@total_comum)
    assert_equal 8.to_d, @controller.instance_variable_get(:@ticket_medio)
  end
end

# AI: GPT web
# Asked to create a test for reports