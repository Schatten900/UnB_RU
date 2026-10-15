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

Feature: Export Global Operations Report
  As a system general administrator
  In order to conduct internal auditing
  I want to be able to export Operation Reports in PDF

  Background:
    Given I am authenticated as staff "999991111"
    And I navigate to the global operations report page

  Scenario: Sad Path - User lacks administrative permissions
    Given my staff account is not a general administrator
    When I click "Export Report"
    Then the global operations report should not be generated or downloaded
    And I should see an error message "You lack permissions for this functionality"

  Scenario: Happy Path - User has administrative permissions
    Given my staff account is a general administrator
    When I click "Export Report"
    Then the global operations report should be generated
    And the PDF file should be downloaded successfully

