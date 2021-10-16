require 'active_record'
require 'logger'

class DatabaseConnector
  class << self
    def establish_connection(config)
      ActiveRecord::Base.logger = config.logger

      configuration = YAML::load(IO.read('config/database.yml'))

      ActiveRecord::Base.establish_connection(configuration)
    end
  end
end
