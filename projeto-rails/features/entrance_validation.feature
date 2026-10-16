# language: pt

Funcionalidade: Validação de entrada
    Como aplicação de controle,
    Eu quero ler a identificação do aluno E verificar se há saldo,
    Para enviar o comando de liberação para a catraca E efetuar o débito da refeição no momento da passagem.

    Contexto:
        Dado que existem os seguintes alunos registrados:
            | identificação | saldo |
            | 221012345     | 15,50 |
            | 232421234     |  0,00 |
            | 251123339     |  3,50 |
            | 231045229     | 45,00 |
        E que a refeição custa R$ 4,50

    Cenário: Saldo Suficiente
        Dado que o aluno apresenta a identificação "221012345"
        Quando leio a identificação do aluno e verifico seu saldo
        Então devo enviar o comando de liberação para a catraca
        E o saldo do aluno deve permanecer em R$ 15,50 até a passagem

    Cenário: Saldo Suficiente
        Dado que o aluno apresenta a identificação "221012345"
        Quando leio a identificação do aluno e verifico seu saldo
        Então devo enviar o comando de liberação para a catraca
        E após a passsagem, o saldo do aluno ser R$ 11,00

    Cenário: Débito no momento da passagem
        Dado que o aluno apresenta a identificação "231045229"
        Quando o aluno passa pela catraca
        Então devo efetuar o débito de R$ 4,50
        E o saldo do aluno deve ser R$ 40,50

    Cenário: Saldo Insuficiente
        Dado que o aluno apresenta a identificação "251123339"
        Quando leio a identificação do aluno e verifico seu saldo
        Então não devo enviar o comando de liberação para a catraca
        E não devo efetuar o débito da refeição
        E o saldo do aluno deve permanecer em R$ 3,50

    Cenário: Saldo Zerado
        Dado que o aluno apresenta a identificação "232421234"
        Quando leio a identificação do aluno e verifico seu saldo
        Então não devo enviar o comando de liberação para a catraca
        E não devo efetuar o débito da refeição
        E o saldo do aluno deve permanecer em R$ 0,00
