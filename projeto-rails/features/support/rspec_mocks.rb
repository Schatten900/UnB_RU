require "rspec/expectations"
require "rspec/mocks"

World(RSpec::Matchers, RSpec::Mocks::ExampleMethods)

Before do
  RSpec::Mocks.setup
end

After do
  begin
    RSpec::Mocks.verify
  ensure
    RSpec::Mocks.teardown
  end
end