require 'logger'

module Logging
  class << self
    def colors
      @colors ||= {
        ERROR: 31, # red
        WARN: 33, # yellow
        INFO: 0,
        DEBUG: 32 # green
      }
    end
    
    def logger
      @logger ||= Logger.new($stdout)
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "\e[#{colors[severity.to_sym]}m#{severity}: #{msg}\e[0m\n"
      end
      @logger
    end

    def logger=(logger)
      @logger = logger
    end
  end

  # Addition
  def self.included(base)
    class << base
      def logger
        Logging.logger
      end
    end
  end

  def logger
    Logging.logger
  end
end
