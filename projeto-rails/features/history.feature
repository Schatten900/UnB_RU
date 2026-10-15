# language: pt

Funcionalidade: Extrato e Histórico
    Como estudante,
    Eu quero visualizar meu extrato de recargas e histórico de refeições,
    Para ter controle sobre meus gastos e utilizações.

    Contexto:
        Dado que existem as seguintes recargas registradas:
            | identificação | data       | valor |
            | 221012345     | 10/10/2026 | 20,00 |
            | 221012345     | 12/10/2026 | 15,00 |
            | 231045229     | 12/10/2026 | 45,00 |
        E que existem as seguintes refeições registradas:
            | identificação | data       | refeição | valor |
            | 221012345     | 10/10/2026 | Almoço   | 4,50  |
            | 221012345     | 12/10/2026 | Jantar   | 4,50  |
            | 231045229     | 12/10/2026 | Almoço   | 4,50  |

    Cenário: Consulta do extrato de recargas
        Dado que estou autenticado como estudante com identificação "221012345"
        Quando consulto meu extrato de recargas
        Então devo ver somente 2 recargas

    Cenário: Consulta do histórico de refeições
        Dado que estou autenticado como estudante com identificação "221012345"
        Quando consulto meu histórico de refeições
        Então devo ver somente as seguintes refeições:
            | data       | refeição | valor |
            | 10/10/2026 | Almoço   | 4,50  |
            | 12/10/2026 | Jantar   | 4,50  |

    Cenário: Consulta sem recargas e refeições registradas
        Dado que estou autenticado como estudante com identificação "232421234"
        Quando consulto meu extrato de recargas e histórico de refeições
        Então devo ser informado de que não tenho recargas registradas
        E devo ser informado de que não tenho refeições registradas

    Cenário: Consulta sem autenticação
        Dado que não estou autenticado
        Quando tento consultar o extrato de recargas e histórico de refeições
        Então devo ser informado de que preciso me autenticar
        E não devo ver nenhum dado de recargas ou refeições

