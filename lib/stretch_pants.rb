require 'search/configuration'
require 'search/searcher'
require 'search/base'
require 'search/filters'
require 'search/query'
require 'search/scope'

module StretchPants
  class << self
    attr_accessor :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def reset
      @configuration = Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
