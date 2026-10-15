
# AI USAGE REPORT
# Gemini 3.1 flash was utilized to check and fix minor syntax issues
# Strategy: Use natural language + modified code template + gherkin code, and ask AI if this is correct, AI should point out problems and fixed code
# Promot: Finally this one, would it work?
# (provided code)
# Output:


# features/step_definitions/shift_time_steps.rb

Given('I am authenticated as staff {string}') do |staff_id|
  @staff_id = staff_id
  @current_user = { id: staff_id, role: :staff } 
end

Given('I navigate to the global operations report page') do
  @page = :global_operations_report
end

Given('my staff account is not a general administrator') do
  @current_user[:role] = :staff # Regular staff, not a general admin
end

Given('my staff account is a general administrator') do
  @current_user[:role] = :general_administrator # General administrator
end

When('I click {string}') do |button_text|
  if button_text == "Export Report"
    # Check permissions based on role
    if @current_user[:role] == :general_administrator
      @report_generated = true
      @pdf_downloaded = true
      @error_message = nil
    else
      @report_generated = false
      @pdf_downloaded = false
      @error_message = "You lack permissions for this functionality"
    end
  end
end

Then('the global operations report should not be generated or downloaded') do
  expect(@report_generated).to be(false)
  expect(@pdf_downloaded).to be(false)
end

Then('I should see an error message {string}') do |expected_message|
  expect(@error_message).to eq(expected_message)
end

Then('the global operations report should be generated') do
  expect(@report_generated).to be(true)
end

Then('the PDF file should be downloaded successfully') do
  expect(@pdf_downloaded).to be(true)
end

=begin

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


=end
