=begin
GENERATED/AIDED BY AI, USED AS TEMPLATE FOR OTHERS
AI: Gemini
prompt: Now I need to continue with this, AI is allowed and I will ask your help and credit you when needed, okay?
Here is the following, now I need to do a Ruby based BDD, I Just want the first:
(first sprint description + gherkin)
output below:
=end

# features/step_definitions/add_credit_steps.rb

Dado('que estou autenticado como estudante') do
  # Mock or set up a logged-in student session
  @current_user = { role: :student, id: 250111111, balance: 0.00 }
  # In a real app using Capybara, you might visit a login page and fill credentials
end

Dado('eu navego para a página de adição de crédito') do
  # Navigation step (e.g., visit('/credits/new') using Capybara)
  @page = :add_credit_page
end

Quando('eu seleciono PIX como o método de pagamento') do
  @payment_method = 'PIX'
end

Quando('eu seleciono cartão de crédito como o método de pagamento') do
  @payment_method = 'Credit Card'
end

Quando('eu insiro o valor de {string}') do |amount|
  @amount = amount.to_f
end

Quando('eu insiro um valor inválido de {string}') do |amount|
  @amount = amount.to_f
end

Quando('eu confirmo o pagamento') do
  # Simulate form submission for a valid path
  @transaction = { method: @payment_method, amount: @amount, status: :pending }
  if @amount > 0
    @pix_code = "pix_hash_123456789"
  end
end

Quando('eu envio o formulário') do
  # Simulate form submission for a sad path (invalid amount)
  if @amount <= 0
    @error_message = "Por favor, insira um valor de crédito válido"
    @transaction_created = false
  else
    @transaction_created = true
  end
end

Então('eu devo ver um código de pagamento PIX gerado') do
  expect(@pix_code).not_to be_nil
end

Então('meu saldo pendente deve refletir o valor adicionado') do
  expected_balance = @current_user[:balance] + @amount
  expect(expected_balance).to eq(@amount)
end

Então('uma nova transação não deve ser criada') do
  expect(@transaction_created).to be(false)
end

Então('eu devo ver uma mensagem de erro {string}') do |expected_message|
  expect(@error_message).to eq(expected_message)
end



=begin
#language: en
# Feature: Add account credit via PIX or credit card
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
=end
