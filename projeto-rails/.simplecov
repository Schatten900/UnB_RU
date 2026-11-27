SimpleCov.load_profile 'rails'
SimpleCov.cover('app/controllers/**/*.rb', 'app/models/**/*.rb')
SimpleCov.group 'Controllers', 'app/controllers'
SimpleCov.group 'Models', 'app/models'

SimpleCov.at_exit do
  result = SimpleCov.result
  result.format!
  %w[Models Controllers].each do |name|
    puts "#{name} coverage: #{result.groups.fetch(name).covered_percent.round(2)}%"
  end
end

SimpleCov.coverage(:line) do
  minimum 90.00, per: group('Models')
  minimum 90.00, per: group('Controllers')
end
