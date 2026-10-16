=begin
AI usage report disclosure
Gemini FLash 3.1 was utilized to debug/fix minor bugs
Strategy: Use natural language + modified code template + gherkin code, and ask AI if this is correct, AI should point out problems and fixed code
Prompt:
So would this work?


Given('I am a general administrator') do
    @user_role = :student
end

Given('I am in staff page') do
  @page = :staff
end

Given('I am authenticated general administrator') do
    @current_user = { role: :general_administrator, id: 999991111, balance: 0.00 }
    # administrator ID placeholder: Starts with 3 9s to delimit staff, 99 for general administrator
end

Given('I am authenticated as non-administrator staff') do
    @current_user = { role: :staff, id: 999991111, balance: 0.00 }
    # administrator ID placeholder: Starts with 3 9s to delimit staff, 99 for general administrator
end


When('I click to navigate to the shift time configurations page') do
    # Simulating backend validation logic based on the student ID provided
    if @current_user[:role] = :general_administrator
        # is general administrator
        @page = :shift_time_configurations
        @error_message = nil
    else
        # is not general administrator 
        @error_message = "You lack permissions for this functionality"
        @page = :staff
    end
end

Then('the page should not be rendered') do
    expect(@page).to be(:staff)
end

Then('I should see an error message {string}') do |expected_message|
    expect(@error_message).to eq(expected_message)
end

Then('I should navigate to the shift configurations page') do
    expect(@page).to be(:shift_time_configurations)
end
Output:
It won't quite work out of the box for two main reason... 

...Here is the fixed version where the step text perfectly matches your Gherkin feature and the logic bug is corrected:
=end

# features/step_definitions/shift_time_steps.rb

Dado('que estou autenticado como funcionário {string}') do |staff_id|
  @staff_id = staff_id
  # Default setup; role will be updated by the next step if specified
  @current_user = { id: staff_id, role: :staff } 
end

Dado('eu navego para a página de gerenciamento de funcionários') do
  @page = :staff_management
end

Dado('que minha conta de funcionário não é de administrador') do
  @current_user[:role] = :staff # Regular staff, not an admin
end

Dado('que minha conta de funcionário é de administrador') do
  @current_user[:role] = :administrator # Administrator
end

Quando('eu clico em {string}') do |button_text|
  if button_text == "Configurar Horário de Turno"
    # Check permissions based on role (using == instead of =)
    if @current_user[:role] == :administrator
      @page = :shift_time_configurations
      @error_message = nil
      @configurations_modifiable = true
    else
      @error_message = "Você não tem permissões para esta funcionalidade"
      @configurations_modifiable = false
    end
  end
end

Então('a página de configuração de turno não deve ser renderizada') do
  expect(@page).not_to be(:shift_time_configurations)
end

Então('eu devo ver uma mensagem de erro {string}') do |expected_message|
  expect(@error_message).to eq(expected_message)
end

Então('a página de configuração de turno deve ser renderizada com todas as informações sobre os horários de turno e os intervalos configuráveis') do
  expect(@page).to be(:shift_time_configurations)
end

Então('eu devo ser capaz de modificar as configurações') do
  expect(@configurations_modifiable).to be(true)
end


=begin
Gherkin feat for reference
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
=end