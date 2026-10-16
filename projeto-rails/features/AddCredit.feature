# Como estudante, eu quero adicionar créditos à minha conta via PIX ou cartão de crédito, para que eu tenha saldo suficiente para acessar os restaurantes.

# REVIEWED BY AI
# AI: Gemini 
# Prompt: Are those cucumber gherkin correct?
# Original attempt at gherkin provided alongside prompt query
# Gemini provided the correct form:


#language: pt
Funcionalidade: Adicionar crédito para conta via PIX ou cartão
  Como um estudante
  Para ter créditos suficientes na conta para acessar o RU
  Eu quero adicionar créditos à minha conta usando PIX ou cartão de crédito

  Contexto:
    Dado que estou autenticado como estudante
    E eu navego para a página de adição de crédito

  Cenário: Caminho Feliz - Adicionar crédito com sucesso via PIX
    Quando eu seleciono PIX como o método de pagamento
    E eu insiro o valor de "20.00"
    E eu confirmo o pagamento
    Então eu devo ver um código de pagamento PIX gerado
    E meu saldo pendente deve refletir o valor adicionado

  Cenário: Caminho Infeliz - Valor de crédito inválido
    Quando eu seleciono cartão de crédito como o método de pagamento
    E eu insiro um valor inválido de "-5.00"
    E eu envio o formulário
    Então uma nova transação não deve ser criada
    E eu devo ver uma mensagem de erro "Por favor, insira um valor de crédito válido"