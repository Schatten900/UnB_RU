# language: pt

Funcionalidade: Histórico Local da Catraca
    Como funcionário do restaurante,
    Eu quero visualizar o histórico de acessos da catraca que estou gerenciando,
    Para realizar auditorias e conferências locais.

    Contexto:
        Dado que estou autenticado como funcionário
        E que estou gerenciando a catraca "04"
        E que existem os seguintes registros de acesso:
            | catraca | matrícula | status    |
            | 04      | 221012345 | Liberado  |
            | 04      | 231045229 | Bloqueado |
            | 02      | 251123339 | Liberado  |

    Cenário: Visualizar histórico da catraca selecionada
        Quando acesso o histórico local
        Então devo visualizar os registros dos alunos "221012345" e "231045229"
        E devo visualizar seus respectivos status de acesso

    Cenário: Não visualizar acessos de outras catracas
        Quando acesso o histórico local
        Então não devo visualizar o registro do aluno "251123339"
