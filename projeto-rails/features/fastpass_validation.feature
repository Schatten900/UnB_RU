# language: pt

Funcionalidade: Validação Rigorosa FastPass
    Como aplicação de controle,
    Eu quero validar o FastPass e o horário de chegada do aluno,
    Para permitir apenas acessos autorizados e efetuar o débito correspondente.

    Contexto:
        Dado que a refeição custa R$ 4,50
        E que o aluno "221021213" possui saldo de R$ 15,50
        E que o aluno "221021212" possui saldo de R$ 15,50
		E que o aluno "221021211" possui saldo de R$ 3,50
		E que o aluno "221021213" não possui FastPass
        E que o aluno "221021212" ganhou um FastPass das 12:15 às 12:30
        E que o aluno "221021211" ganhou um FastPass das 12:15 às 12:30

    Cenário: Autorizar FastPass válido no horário permitido
        Dado que a catraca está no modo exclusivo FastPass
        Quando o aluno "221021212" apresenta seu QR Code às 12:20
        Então a catraca deve liberar sua entrada
        E seu saldo deve permanecer em R$ 15,50
        Quando a passagem pela catraca é confirmada
        Então seu saldo deve ser reduzido para R$ 11,00

    Cenário: Bloquear FastPass fora do horário
        Dado que a catraca está no modo exclusivo FastPass
        Quando o aluno "221021212" apresenta seu QR Code às 12:31
        Então a entrada deve ser bloqueada
        E seu saldo deve permanecer em R$ 15,50

	Cenário: Bloquear FastPass com saldo insuficiente
        Dado que a catraca está no modo exclusivo FastPass
        Quando o aluno "221021211" apresenta seu QR Code às 12:20
        Então a entrada deve ser bloqueada
        E seu saldo deve permanecer em R$ 3,50

    Cenário: Bloquear aluno sem FastPass no modo exclusivo
        Dado que a catraca está no modo exclusivo FastPass
        Quando o aluno "221021213" apresenta seu QR Code
        Então a entrada deve ser bloqueada
        E seu saldo deve permanecer em R$ 15,50
