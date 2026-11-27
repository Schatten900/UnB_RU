# models/usuario.rb

##
# Model responsável por representar os usuários da aplicação,
# incluindo administradores, funcionários e estudantes.
#
# Gerencia os dados cadastrais, autenticação, saldo financeiro,
# histórico de acessos e relacionamento com recargas, turnos
# e restaurantes.
#
# A matrícula é utilizada como chave primária do registro.
#
class Usuario < ApplicationRecord
  require 'bcrypt'

  self.primary_key = :matricula

  ##
  # Associação com as recargas realizadas pelo usuário.
  #
  # Utiliza a matrícula como chave estrangeira e chave primária
  # de referência. Quando um usuário é excluído, suas recargas
  # também são excluídas.
  has_many :recargas,
           foreign_key: :usuario_matricula,
           primary_key: :matricula,
           dependent: :destroy

  ##
  # Associação com os registros de acesso do usuário.
  #
  # Utiliza a matrícula para localizar os acessos correspondentes.
  has_many :acessos,
           foreign_key: :usuario_matricula,
           primary_key: :matricula

  ##
  # Associação opcional com o turno do usuário.
  belongs_to :turno, optional: true

  ##
  # Associação opcional com o restaurante do usuário.
  belongs_to :restaurante, optional: true

  ##
  # Valida a presença, unicidade e formato numérico da matrícula.
  validates :matricula,
            presence: true,
            uniqueness: true,
            format: { with: /\A\d{9}\z/ }

  ##
  # Valida a presença do nome do usuário.
  validates :nome, presence: true

  ##
  # Valida a presença do hash da senha.
  validates :senha_hash, presence: true

  ##
  # Valida que o saldo do usuário seja maior ou igual a zero.
  validates :saldo, numericality: { greater_than_or_equal_to: 0 }

  ##
  # Define automaticamente o perfil do usuário antes de cada validação.
  before_validation :definir_perfil

  ##
  # Verifica se o usuário possui perfil de administrador.
  #
  # A identificação é realizada verificando se a matrícula
  # começa com o prefixo "9999".
  #
  # @return [Boolean] Retorna true quando a matrícula começa
  #   com "9999" e false caso contrário.
  #
  # Efeito colateral: Não modifica atributos nem registros
  # do banco de dados.
  def administrador?
    matricula.to_s.start_with?('9999')
  end

  ##
  # Verifica se o usuário possui perfil de funcionário.
  #
  # Considera funcionário o usuário cuja matrícula começa
  # com "999", desde que ele não seja administrador.
  #
  # @return [Boolean] Retorna true quando a matrícula começa
  #   com "999" e não corresponde a um administrador.
  #   Retorna false nos demais casos.
  #
  # Efeito colateral: Não modifica atributos nem registros
  # do banco de dados.
  def funcionario?
    matricula.to_s.start_with?('999') && !administrador?
  end

  ##
  # Verifica se o usuário possui perfil de estudante.
  #
  # Considera estudante todo usuário que não seja classificado
  # como administrador ou funcionário.
  #
  # @return [Boolean] Retorna true quando o usuário não é
  #   administrador nem funcionário. Retorna false caso contrário.
  #
  # Efeito colateral: Não modifica atributos nem registros
  # do banco de dados.
  def estudante?
    !funcionario? && !administrador?
  end

  ##
  # Verifica se o saldo atual do usuário é suficiente para
  # pagar o preço de um turno.
  #
  # @param turno [Turno] Turno cujo preço será utilizado
  #   na comparação com o saldo do usuário.
  #
  # @return [Boolean] Retorna true quando o saldo é maior
  #   ou igual ao preço do turno. Retorna false caso contrário.
  #
  # Efeito colateral: Consulta os atributos de saldo e preço,
  # sem modificar registros do banco de dados.
  def saldo_suficiente_para?(turno)
    saldo >= turno.preco
  end

  ##
  # Retorna a associação de recargas pertencentes ao usuário.
  #
  # @return [ActiveRecord::Associations::CollectionProxy] Coleção
  #   de recargas associadas ao usuário.
  #
  # Efeito colateral: Disponibiliza a associação de recargas.
  # A consulta ao banco de dados ocorre quando os registros
  # são carregados, caso ainda não estejam em memória.
  def extrato_recargas
    recargas
  end

  ##
  # Retorna o histórico de refeições do usuário, considerando
  # apenas os registros de acesso que possuem uma data de passagem.
  #
  # Inclui a associação com turno para facilitar o acesso
  # às informações do turno de cada refeição.
  #
  # @return [ActiveRecord::Relation] Relação de acessos que
  #   possuem passagem_em diferente de nil, incluindo seus turnos.
  #
  # Efeito colateral: Constrói uma consulta ao banco de dados.
  # Os registros são efetivamente consultados quando a relação
  # é carregada ou utilizada.
  def historico_refeicoes
    acessos.where.not(passagem_em: nil).includes(:turno)
  end

  ##
  # Calcula o valor total das recargas que ainda estão pendentes
  # para o usuário.
  #
  # @return [Numeric] Soma dos valores das recargas pendentes.
  #   Retorna zero quando não existem recargas pendentes.
  #
  # Efeito colateral: Executa uma consulta de agregação no banco
  # de dados, sem modificar os registros.
  def saldo_pendente
    recargas.pendente.sum(:valor)
  end

  ##
  # Define a senha do usuário, armazenando seu hash criptográfico
  # no atributo senha_hash.
  #
  # Caso o valor recebido esteja vazio, a operação é interrompida
  # sem modificar o hash existente.
  #
  # @param valor [String] Senha em texto informada pelo usuário,
  #   utilizada para gerar o hash criptográfico.
  #
  # @return [String, nil] Retorna o valor atribuído a senha_hash
  #   quando a senha é processada. Retorna nil quando o valor
  #   informado está vazio.
  #
  # Efeito colateral: Modifica o atributo senha_hash do objeto
  # em memória. A persistência no banco de dados depende
  # de uma operação posterior de salvamento do registro.
  def senha=(valor)
    return if valor.blank?

    self.senha_hash = BCrypt::Password.create(valor)
  end

  ##
  # Verifica se a senha informada corresponde ao hash armazenado
  # no registro do usuário.
  #
  # Utiliza BCrypt para comparar a senha recebida com o hash.
  # Caso o valor esteja vazio, o hash não esteja preenchido
  # ou o hash seja inválido, a autenticação é considerada falsa.
  #
  # @param valor [String] Senha em texto informada durante
  #   o processo de autenticação.
  #
  # @return [Boolean] Retorna true quando a senha corresponde
  #   ao hash armazenado. Retorna false quando a senha está vazia,
  #   o hash não existe, a senha não corresponde ou o hash é inválido.
  #
  # Efeito colateral: Realiza a verificação criptográfica da senha,
  # sem modificar atributos nem registros do banco de dados.
  def senha_correta?(valor)
    return false if valor.blank? || senha_hash.blank?

    BCrypt::Password.new(senha_hash) == valor
  rescue BCrypt::Errors::InvalidHash
    false
  end

  private

  ##
  # Define automaticamente o perfil do usuário com base no prefixo
  # de sua matrícula.
  #
  # Usuários com matrícula iniciada por "9999" são classificados
  # como administradores. Matrículas iniciadas por "999", exceto
  # as de administradores, são classificadas como funcionários.
  # Os demais usuários são classificados como estudantes.
  #
  # Este método é executado automaticamente pelo callback
  # before_validation.
  #
  # @return [String] Retorna o perfil atribuído ao atributo perfil:
  #   "administrador", "funcionario" ou "estudante".
  #
  # Efeito colateral: Modifica o atributo perfil do objeto
  # em memória antes da validação. A persistência ocorre
  # quando o registro é salvo no banco de dados.
  def definir_perfil
    self.perfil =
      if administrador?
        'administrador'
      elsif funcionario?
        'funcionario'
      else
        'estudante'
      end
  end
end
