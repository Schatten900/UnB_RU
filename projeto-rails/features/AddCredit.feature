# Como estudante, eu quero adicionar créditos à minha conta via PIX ou cartão de crédito, para que eu tenha saldo suficiente para acessar os restaurantes.

# REVIEWED BY AI
# AI: Gemini 
# Prompt: Are those cucumber gherkin correct?
# Original attempt at gherkin provided alongside prompt query
# Gemini provided the correct form:


#language: en
Feature: Add account credit via PIX or credit card
  As a student
  In order to have sufficient balance to access the university restaurant (RU)
  I want to add credits to my account using PIX or a credit card

  Background:
    Given I am authenticated as a student
    And I navigate to the add credit page

  Scenario: Happy Path - Successfully add credit via PIX
    When I select PIX as the payment method
    And I enter the amount of "20.00"
    And I confirm the payment
    Then I should see a PIX payment code generated
    And my pending balance should reflect the added amount

  Scenario: Sad Path - Invalid credit amount
    When I select credit card as the payment method
    And I enter an invalid amount of "-5.00"
    And I submit the form
    Then a new transaction should not be created
    And I should see an error message "Please enter a valid credit amount"