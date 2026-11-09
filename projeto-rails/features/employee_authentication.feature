# language: pt


Funcionalidade: Autenticação do funcionario
    Como funcionário do restaurante, 
    eu quero fazer login na aplicação de controle, 
    para autenticar minha sessão e operar o sistema de forma segura


Contexto:
    Dado que existem os seguintes funcionarios:
        | funcionario  |  matricula  |
        |  jose        |  999149608  |
        |  fernando    |  999549803  |
        |  maria       |  999049601  |

Cenario: Login realizado dentro do horário permitido 
    Dado que José tentou fazer login às 11:00
    Quando ele informa suas credenciais válidas
    Entao o sistema deve autentificar sua sessão
    E permitir operar o sistema de forma segura

Cenario: Login realizado fora do horário permitido 
    Dado que Fernando tentou fazer login às 15:00
    Quando ele informa suas credenciais válidas
    Entao o sistema deverá negar a autenticação
    E impedir o acesso ao sistema

Cenario: Sistema indisponivel durante o login
    Dado que Maria tentou fazer login às 12:00
    E que o sistema está indisponivel
    Quando ela solicita a autenticacao com credenciais válidas
    Entao o sistema não deve estabelecer uma sessão autenticada
    E deverá informar que o serviço está indisponivel

