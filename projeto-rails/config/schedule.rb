set :path, File.expand_path("..", __dir__)
set :environment, ENV.fetch("RAILS_ENV", "production")
set :output, "log/cron.log"

every 1.minute do
  runner "NotificarFastPassJob.perform_now"
end