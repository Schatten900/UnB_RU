# Como administrador, eu quero definir os horários dos turnos e dividi-los em time-frames configuráveis, para organizar a distribuição do FastPass.

#language: en
Feature: Define shift time and divide in configurable timeframes
  As an administrator
  In order to organize FastPass distribution
  I want to be able to define shift times and divide them into configurable timeframes

  Background:
    Given I am authenticated as staff "999991111"
    And I navigate to the staff management page

  Scenario: Sad Path - User lacks administrative permissions
    Given my staff account is not an administrator
    When I click "Configure Shift Time"
    Then the shift configuration page should not render
    And I should see an error message "You lack permissions for this functionality"

  Scenario: Happy Path - User has administrative permissions
    Given my staff account is an administrator
    When I click "Configure Shift Time"
    Then the shift configuration page should render with all information on shift times and configurable time frames
    And I should be able to modify the configurations