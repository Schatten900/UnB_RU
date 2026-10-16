# REPORT AI USAGE:
# Reason: To validate/fix/correct/learn Gherkin syntax
# Strategy: Straightfoward question for GEMINI 3.1 flash in Natural language, followed by validation by testing 
# PROMPT START
# Something like this?
#    #language: en
#    As a system general administrator
#    For the sake of internal auditing
#    I want to be able to export Operation Reports in PDF
#
#    Context:
#        And navigate to the export global operations report
#
#    Cenario SAD:
#        When I click export report
#        And my staff account is not general administrator
#        global operations report is not generated, nor downloaded
#        An error message is raised "You lack permissions for this functionality
#
#    Cenario HAPPY:
#        When I click export report
#        And my staff account is general administrator
#        global operations report is generated
#        global operations report is downloaded
# For this:
# Eu, como administrador geral do sistema, quero poder exportar o Relatório Global de Operação com finalidade de auditoria interna.
# Is my Gherkin correct? 
# AI RES:
# Your Gherkin is mostly correct in structure and logic, but it contains syntax errors and standard Gherkin formatting issues that will prevent Cucumber from parsing and executing it properly.
# language: en

#language: pt
Funcionalidade: Exportar Relatório de Operações Globais
  Como um administrador geral do sistema
  Para realizar auditorias internas
  Eu quero poder exportar Relatórios de Operações em PDF

  Contexto:
    Dado que estou autenticado como funcionário "999991111"
    E eu navego para a página do relatório de operações globais

  Cenário: Caminho Infeliz - O usuário não possui permissões administrativas
    Dado que minha conta de funcionário não é de administrador geral
    Quando eu clico em "Exportar Relatório"
    Então o relatório de operações globais não deve ser gerado ou baixado
    E eu devo ver uma mensagem de erro "Você não tem permissões para esta funcionalidade"

  Cenário: Caminho Feliz - O usuário possui permissões administrativas
    Dado que minha conta de funcionário é de administrador geral
    Quando eu clico em "Exportar Relatório"
    Então o relatório de operações globais deve ser gerado
    E o arquivo PDF deve ser baixado com sucesso

