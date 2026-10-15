# language: pt

Funcionalidade: Inscrição Única no FastPass
    Como estudante,
    Eu quero me inscrever no sorteio gratuito do FastPass escolhendo apenas um time-frame por turno de refeição,
    Para tentar garantir meu acesso sem filas.

    Contexto:
        Dado que as inscrições para o sorteio do FastPass de 16/10/2026 estão abertas
        E que existem os seguintes time-frames disponíveis nesse sorteio:
            | turno  | time-frame  |
            | Almoço | 12:00-12:30 |
            | Almoço | 12:30-13:00 |
            | Jantar | 18:00-18:30 |
            | Jantar | 18:30-19:00 |

    Cenário: Inscrição em um time-frame
        Dado que estou autenticado como estudante
        E não estou inscrito no turno "Almoço" desse sorteio
        Quando escolho o time-frame "12:00-12:30" do turno "Almoço"
        E confirmo minha inscrição
        Então devo ver a confirmação da minha inscrição nesse time-frame

    Cenário: Inscrição em turnos diferentes
        Dado que estou autenticado como estudante
        E estou inscrito no time-frame "12:00-12:30" do turno "Almoço" desse sorteio
        E não estou inscrito no turno "Jantar" desse sorteio
        Quando escolho o time-frame "18:00-18:30" do turno "Jantar"
        E confirmo minha inscrição
        Então devo ver as seguintes inscrições nesse sorteio:
            | turno  | time-frame  |
            | Almoço | 12:00-12:30 |
            | Jantar | 18:00-18:30 |

    Cenário: Inscrição gratuita 
        Dado que estou autenticado como estudante 
        E meu saldo é R$ 0 
        E não estou inscrito no turno "Almoço" desse sorteio
        Quando escolho o time-frame "12:00-12:30" do turno "Almoço"
        E confirmo minha inscrição
        Então devo ver a confirmação da minha inscrição nesse time-frame

    Cenário: Inscrição em outro time-frame do mesmo turno
        Dado que estou autenticado como estudante
        E estou inscrito no time-frame "12:00-12:30" do turno "Almoço" desse sorteio
        Quando escolho o time-frame "12:30-13:00" do turno "Almoço"
        E tento confirmar outra inscrição
        Então devo ser informado de que só posso escolher um time-frame por turno de refeição
        E devo continuar inscrito somente no time-frame "12:00-12:30" do turno "Almoço"

    Cenário: Inscrição sem escolher um time-frame
        Dado que estou autenticado como estudante
        E não estou inscrito no turno "Almoço" desse sorteio
        Quando tento confirmar minha inscrição no turno "Almoço" sem escolher um time-frame
        Então devo ser informado de que preciso escolher um time-frame
        E não devo ter uma inscrição confirmada nesse turno
