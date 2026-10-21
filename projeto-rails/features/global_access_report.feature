# language: pt

Funcionalidade: Relatório Global de Acessos
    Como administrador, 
    Eu quero visualizar o histórico completo de todos os acessos do campus 
    E poder filtrar e agrupar os dados por restaurante e por catraca específica, 
    Para ter uma visão gerencial de toda a operação.

    Contexto: 
        Dado que existem os seguintes acessos registrados:
        | restaurante               | catraca |
        | RU Darcy Ribeiro - Piso 1 |    1    |
        | RU Darcy Ribeiro - Piso 2 |    3    |
        | RU Darcy Ribeiro - Piso 3 |    5    |
        | RU Darcy Ribeiro - Piso 2 |    4    |
        | RU Darcy Ribeiro - Piso 2 |    4    |
        | RU Darcy Ribeiro - Piso 1 |    2    |
           
    Cenário: Consulta padrão 
        Dado que estou autenticado como administrador
        Quando consulto o relatório global de acessos sem filtros
        Então devo ver 6 acessos

    Cenário: Consulta com filtro pelo restaurante
        Dado que estou autenticado como administrador
        Quando consulto o relatório global de acessos 
        E filtro pelo restaurante RU Darcy Ribeiro - Piso 1  
        Então devo ver 2 acessos

    Cenário: Consulta com filtro pela catraca
        Dado que estou autenticado como administrador
        Quando consulto o relatório global de acessos 
        E filtro pela catraca 5 
        Então devo ver 1 acesso
    
    Cenário: Consulta com filtro pelo restaurante e catraca
        Dado que estou autenticado como administrador
        Quando consulto o relatório global de acessos 
        E filtro pela catraca 5 
        E filtro pelo restaurante RU Darcy Ribeiro - Piso 1
        Então não devo ver nenhum acesso

    Cenário: Consulta sem permissão
        Dado que estou autenticado como estudante
        Quando consulto o relatório global de acessos
        Então devo ser informado de que não tenho permissão
        E não devo ver nenhum resultado
    

        
            