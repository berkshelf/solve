require "rubygems"
require "bundler"
require "spork"

Spork.prefork do
  require "rspec"

  APP_ROOT = File.expand_path("../../", __FILE__)

  Dir[File.join(APP_ROOT, "spec/support/**/*.rb")].each { |f| require f }

  RSpec.configure do |config|
    config.mock_with :rspec
    config.filter_run focus: true
    config.run_all_when_everything_filtered = true

    # Run specs in a random order
    config.order = :random
  end
end

Spork.each_run do
  require "solve"
end

# Useful for debugging the solver - simply add `ui: TestUI` to a resolver call
class TestUI
  def self.say(message = "")
    $stdout.print(message + "\n")
    $stdout.flush
  end
end
