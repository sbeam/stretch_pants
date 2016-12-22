module StretchPants
  class Configuration
    attr_accessor :index_env,
                  :force_post,
                  :elasticsearch_host,
                  :log_level,
                  :trace_client

    def initialize
      @index_env = nil
      @force_post = false
      @elasticsearch_host = 'http://localhost:9200'
      @log_level = :warn
      @trace_client = nil
    end
  end
end
