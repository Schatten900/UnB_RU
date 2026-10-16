# language: pt

Funcionalidade: Gestão de Restaurantes e Catracas
    Como administrador,
    Eu quero cadastrar, editar e remover restaurantes e suas catracas,
    Para gerenciar os pontos de acesso disponíveis.

    Cenário: Cadastrar restaurante e catraca
        Dado que estou autenticado como administrador
        Quando cadastro o restaurante "RU Darcy Ribeiro"
        E cadastro a catraca "04" associada a esse restaurante
        Então o restaurante deve aparecer na lista de restaurantes
        E a catraca "04" deve aparecer associada a ele

    Cenário: Editar restaurante e catraca
        Dado que estou autenticado como administrador
        E que existe o restaurante "RU Gama" com a catraca "01" no piso 1
        Quando altero o nome do restaurante para "RU FCTE"
        E altero o piso da catraca "01" para 2
        Então as alterações devem ser salvas e exibidas

    Cenário: Remover restaurante e catraca
        Dado que estou autenticado como administrador
        E que existe o restaurante "RU Gama" com a catraca "01"
        Quando removo a catraca "01"
        E removo o restaurante "RU Gama"
        Então ambos não devem mais aparecer na lista de cadastros

    Cenário: Impedir gerenciamento por usuário não autorizado
        Dado que estou autenticado como funcionário não administrador
        Quando tento cadastrar um novo restaurante
        Então a operação deve ser negada
        E o restaurante não deve ser cadastrado
