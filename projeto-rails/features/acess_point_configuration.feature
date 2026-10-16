# language: pt


Funcionalidade: Configuração de ponto de rede

    Como funcionário do restaurante,
    logo após o login, eu quero selecionar em qual restaurante vou gerenciar, 
    para que o sistema direcione as regras corretamente e grave os logs corretamente.

Contexto:

    Dado que o funcionario está autenticado
    E que existem os seguintes restaurantes disponiveis:
        | restaurante | andar |
        |      1      |   1   |
        |      2      |   1   |
        |      3      |   2   |
        |      4      |   2   |
        |      5      |   3   |
        |      6      |   3   |


Cenário: Selecionar restaurante para gerenciamento
    Quando o funcionário selecionar o restaurante 3
    Então o sistema deve configurar o restaurante 3 como ponto de gerenciamento
    E deve aplicar as regras correspondentes ao restaurante selecionado
    E deve registrar os logs associados ao restaurante 3

Cenário: Tentar acessar o gerenciamento sem autenticação
    Dado que o funcionário não está autenticado
    Quando ele tentar acessar a configuração do ponto de rede
    Então o sistema deve negar o acesso
    E não deve permitir a configuração do restaurante

Cenário: Tentar acessar o gerenciamento com o sistema indisponivel
    Dado que o funcionário não está autenticado
    Quando ele tentar acessar a configuração do ponto de rede
    E o sistema está indisponivel
    Então o sistema deve informar que o sistema está indisponivel
    E não permitir a configuração do restaurante
