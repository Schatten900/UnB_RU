# Como administrador, eu quero definir os horários dos turnos e dividi-los em time-frames configuráveis, para organizar a distribuição do FastPass.

#language: pt
Funcionalidade: Definir horário de turno e dividi-lo em intervalos configuráveis
  Como um administrador
  Para organizar a distribuição do FastPass
  Eu quero poder definir horários de turno e dividi-los em intervalos configuráveis

  Contexto:
    Dado que estou autenticado como funcionário "999991111"
    E eu navego para a página de gerenciamento de funcionários

  Cenário: Caminho Infeliz - O usuário não possui permissões administrativas
    Dado que minha conta de funcionário não é de administrador
    Quando eu clico em "Configurar Horário de Turno"
    Então a página de configuração de turno não deve ser renderizada
    E eu devo ver uma mensagem de erro "Você não tem permissões para esta funcionalidade"

  Cenário: Caminho Feliz - O usuário possui permissões administrativas
    Dado que minha conta de funcionário é de administrador
    Quando eu clico em "Configurar Horário de Turno"
    Então a página de configuração de turno deve ser renderizada com todas as informações sobre os horários de turno e os intervalos configuráveis
    E eu devo ser capaz de modificar as configurações