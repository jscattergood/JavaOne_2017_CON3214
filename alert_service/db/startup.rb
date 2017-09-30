require 'active_record'
require 'activerecord-jdbc-adapter'

config_file = File.join(__dir__, 'conf', 'database.yml')
configuration = YAML.safe_load(File.read(config_file))
ActiveRecord::Base.establish_connection(configuration)

migrations = File.join(__dir__, 'migrate')
ActiveRecord::Migrator.migrate(migrations, 1)
