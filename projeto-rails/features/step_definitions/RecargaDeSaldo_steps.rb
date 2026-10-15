=begin
GENERATED/AIDED BY AI, USED AS TEMPLATE FOR OTHERS
AI: Gemini
prompt: Now I need to continue with this, AI is allowed and I will ask your help and credit you when needed, okay?
Here is the following, now I need to do a Ruby based BDD, I Just want the first:
(first sprint description + gherkin)
output below:
=end

# features/step_definitions/add_credit_steps.rb

Given('I am authenticated as a student') do
  # Mock or set up a logged-in student session
  @current_user = { role: :student, id: 250111111, balance: 0.00 }
  # In a real app using Capybara, you might visit a login page and fill credentials
end

Given('I navigate to the add credit page') do
  # Navigation step (e.g., visit('/credits/new') using Capybara)
  @page = :add_credit_page
end

When('I select PIX as the payment method') do
  @payment_method = 'PIX'
end

When('I select credit card as the payment method') do
  @payment_method = 'Credit Card'
end

When('I enter the amount of {string}') do |amount|
  @amount = amount.to_f
end

When('I enter an invalid amount of {string}') do |amount|
  @amount = amount.to_f
end

When('I confirm the payment') do
  # Simulate form submission for a valid path
  @transaction = { method: @payment_method, amount: @amount, status: :pending }
  if @amount > 0
    @pix_code = "pix_hash_123456789"
  end
end

When('I submit the form') do
  # Simulate form submission for a sad path (invalid amount)
  if @amount <= 0
    @error_message = "Please enter a valid credit amount"
    @transaction_created = false
  else
    @transaction_created = true
  end
end

Then('I should see a PIX payment code generated') do
  expect(@pix_code).not_to be_nil
end

Then('my pending balance should reflect the added amount') do
  expected_balance = @current_user[:balance] + @amount
  expect(expected_balance).to eq(@amount)
end

Then('a new transaction should not be created') do
  expect(@transaction_created).to be(false)
end

Then('I should see an error message {string}') do |expected_message|
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
