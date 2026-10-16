# language: pt


Funcionalidade: Notificação de Sorteio
    Como estudante, 
    eu quero ser notificado se ganhei ou não o FastPass 1 hora antes do turno, 
    para que eu possa planejar meu horário de ida ao RU.


Contexto:
    Dado que existe um sorteio de FastPass
    E que os seguintes estudantes participaram do sorteio:
    | matrícula | resultado  |
    | 221021231 | não ganhou |
    | 241071531 | não ganhou |
    | 201051831 | ganhou     |


Cenario: Notificar estudante contemplado no sorteio
    Dado que o estudante "201051831" ganhou o FastPass
    E que falta uma hora para o turno desse estudante
    Quando chegar o horário de envio das notificações
    Então o sistema deve enviar uma notificação informando que ele ganhou o FastPass
    

Cenario: Notificar estudante não contemplado no sorteio
    Dado que o estudante "241071531" não ganhou o FastPass
    E que falta uma hora para o turno desse estudante
    Quando chegar o horário de envio das notificações
    Então o sistema deve enviar uma notificação informando que ele não ganhou o FastPass

Cenario: Serviço de notificação indisponível
    Dado que o estudante "201051831" ganhou o sorteio de FastPass
    E que falta uma hora para o turno desse estudante
    E que o serviço de notificação está indisponivel
    Quando chegar o horário de envio das notificações
    Então o sistema não deve confirmar o envio da notificação
    E deve tratar a falha de envio conforme a regra definida pelo sistema


