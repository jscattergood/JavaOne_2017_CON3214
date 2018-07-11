begin
  require 'rspec/core/rake_task'
  require 'rspec_junit_formatter'

  task default: %w[spec]

  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = '--format RspecJunitFormatter  --out test-results.xml'
  end

  task :build do
    sh 'docker build . -t stockalert'
  end

  task :up do
    sh 'docker-compose up'
  end
rescue LoadError => e
  puts "error executing task #{e.message}"
end

