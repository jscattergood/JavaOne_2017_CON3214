$LOAD_PATH << '.'

require 'bundler'
require 'common/common'

Bundler.require(:default, :test)

if ENV['NO_COVERAGE'].nil?
  SimpleCov.start { add_filter 'spec/*' }
  SimpleCov.coverage_dir 'coverage'
  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter,
    SimpleCov::Formatter::RcovFormatter
  ]
end

Dir['spec/support/**/*.rb'].each { |file| require "./#{file}" }

RSpec.configure do |config|

  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation
end
