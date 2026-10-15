# Como estudante, eu quero me cadastrar no sistema utilizando minha matrícula, para que eu possa criar minha conta de acesso ao RU.
# Use database of all active students or simply check if student ID is active?


#language: en
Feature: Create an RU access account with student ID
  As a student
  In order to access the University Restaurant (RU)
  I want to use my student ID to create an access account

  Background:
    Given I am a student
    And I do not have an account
    And I navigate to the sign-up page and fill in the create an account form

  Scenario: Sad Path - User uses invalid student ID
    Given I provide an invalid student ID
    When I click sign up
    Then a new account should not be created
    And I should see an error message "You must provide a valid student ID"

  Scenario: Happy Path - User provides a valid student ID
    Given I provide a valid student ID
    When I click sign up
    Then a new account should be created
    And I should be logged in with my new account


