

# AI USAGE REPORT
# Gemini 3.1 flash was utilized to check and fix minor syntax issues
# Promot: Something like this for the next one? 
# (provided code)
# Output:

Given('que eu sou um estudante') do
  @user_role = :student
end

Given('eu não tenho uma conta') do
  @current_user = nil
  @account_created = false
end

Given('eu navego até a página de cadastro e preencho o formulário de criação de conta') do
  @page = :sign_up_page
  @form_data = { role: @user_role }
end

Given('euforneço um número de estudante inválido') do
  @form_data[:student_id] = "albert" # Non-numeric / invalid format
end

Given('eu forneço um número de estudante válido') do
  @form_data[:student_id] = "250011111"
end

Quando('eu clico em cadastrar') do
  # Simulating backend validation logic based on the student ID provided
  if @form_data[:student_id] =~ /\A\d+\z/
    # Valid ID (numeric only)
    @account_created = true
    @current_user = {
      student_id: @form_data[:student_id],
      role: :student,
      balance: 0.00,
      logged_in: true
    }
    @error_message = nil
  else
    # Invalid ID
    @account_created = false
    @error_message = "Você deve fornecer um número de estudante válido"
  end
end

Então('uma nova conta não deve ser criada') do
  expect(@account_created).to be(false)
  expect(@current_user).to be_nil
end

Então('eu devo ver uma mensagem de erro {string}') do |expected_message|
  expect(@error_message).to eq(expected_message)
end

Então('uma nova conta deve ser criada') do
  expect(@account_created).to be(true)
  expect(@current_user).not_to be_nil
end

Então('eu devo estar logado com minha nova conta') do
  expect(@current_user[:logged_in]).to be(true)
end



=begin
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
=end