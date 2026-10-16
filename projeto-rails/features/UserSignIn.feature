# Como estudante, eu quero me cadastrar no sistema utilizando minha matrícula, para que eu possa criar minha conta de acesso ao RU.
# Use database of all active students or simply check if student ID is active?

#language: pt
Funcionalidade: Criar uma conta de acesso ao RU com a carteirinha de estudante
  Como um estudante
  Para poder acessar o Restaurante Universitário (RU)
  Eu quero usar minha carteirinha de estudante para criar uma conta de acesso

Contexto:
    Dado que eu sou um estudante
    E eu não tenho uma conta
    E eu navego até a página de cadastro e preencho o formulário de criação de conta

  Cenário: Caminho Infeliz - Usuário usa um número de estudante inválido
    Dado que euforneço um número de estudante inválido
    Quando eu clico em cadastrar
    Então uma nova conta não deve ser criada
    E eu devo ver uma mensagem de erro "Você deve fornecer um número de estudante válido"

  Cenário: Caminho Feliz - Usuário fornece um número de estudante válido
    Dado que eu forneço um número de estudante válido
    Quando eu clico em cadastrar
    Então uma nova conta deve ser criada
    E eu devo estar logado com minha nova conta



