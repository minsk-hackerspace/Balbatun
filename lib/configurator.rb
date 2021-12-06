require 'logger'
require 'journald/logger'
require 'yaml'
require 'colorize'

require './lib/database_connector'

class ColorFormatter < Logger::Formatter
  include Logger::Severity
  COLOR_MAP = {
    "DEBUG" => :white,
    "INFO" => :green,
    "WARN" => :yellow,
    "ERROR" => :red,
    "FATAL" => :red,
    "UNKNOWN" => :white
  }

  def call(severity, time, progname, msg)
    text = super
    text.colorize(COLOR_MAP[severity])
  end
end


class Configurator
  def initialize
    @secrets = YAML::load(IO.read('config/secrets.yml'))
    @config = YAML::load(IO.read('config/config.yml'))

    setup_database
  end

  def token
    @secrets['telegram_bot_token']
  end

  def bramnik_token
    @secrets['bramnik_api_token']
  end

  def logger
    case @config['logger']
    when 'stdout'
      l = Logger.new(STDOUT, Logger::DEBUG)
      l.formatter = ColorFormatter.new
    when 'journald'
      l = Journald::Logger.new('Balbatun', Journald::LOG_DEBUG)
    else
      STDERR.puts "Logger is not defined in the config, define please"
      exit 1
    end

    l
  end

  def tz
    @config['tz']
  end

  def controllers_enabled
    @config['controllers_enabled'] || []
  end

  def cameras
    @config['cameras']
  end

  private

  def setup_database
    DatabaseConnector.establish_connection(self)
  end
end
