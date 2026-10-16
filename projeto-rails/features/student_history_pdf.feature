# language: pt

Funcionalidade: Exportação em PDF do Histórico do Estudante
    Como estudante,
    Eu quero exportar meu extrato e histórico de refeições em PDF,
    Para controlar melhor minhas finanças.

    Cenário: Exportar histórico com filtros aplicados
        Dado que estou autenticado como estudante
        E que possuo 6 lançamentos em maio e 1 em abril
        E que o histórico exibe 5 lançamentos por página
        Quando filtro os lançamentos pelo mês de maio
        E solicito a exportação em PDF
        Então devo receber um arquivo PDF
        E o arquivo deve conter os 6 lançamentos de maio
        E não deve conter o lançamento de abril


    Cenário: Exportar histórico sem lançamentos
        Dado que estou autenticado como estudante
        E que não possuo lançamentos em abril
        Quando filtro os lançamentos pelo mês de abril
        E solicito a exportação em PDF
        Então devo receber um arquivo PDF
        E o arquivo não deve conter lançamentos
