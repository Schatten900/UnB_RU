# language: pt

Funcionalidade: Cardapio da refeição atual
    Como estudante, 
    eu quero poder ver o cardápio da refeição que esteja sendo servida agora. 
    Incluindo as opções padrão, ovolactovegetariano e vegetariano estrito.

Cenario: Cardapio disponível
    Dado que existe um cardapio para a refeicao atual
    E que o cardápio contém as seguintes opções:
    | tipo de alimento    | proteina                      |
    | padrão              | Filé de Frango                |
    | ovolactovegetariano | Suflê de chuchu                |
    | vegetariano estrito | Quinoa com legumes refogados  |
    Quando o estudante acessar o cardapio da refeição atual
    Entao o sistema deve informar as opções da refeição atual

Cenario: Cardapio indisponivel
    Dado que não existe um cardápio para a refeição atual
    Quando o estudante acessar o cardapio da refeição atual
    Entao o sistema deve informa que o cardapio não esta disponivel
