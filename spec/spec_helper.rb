require 'bundler/setup'
Bundler.setup

require 'stretch_pants'

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.order = "random"
end
