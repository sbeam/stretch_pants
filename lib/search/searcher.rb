require 'elasticsearch-transport'
require 'hashie/mash'

module StretchPants
  class Searcher < Elasticsearch::Transport::Client

    class << self

      def perform index, query
        response = self.elasticsearch_client.search(index: index, body: query)
        self.collect_hits response
      end

      def collect_hits response
        response = JSON.parse(response) unless response.is_a? Hash
        mash = Hashie::Mash.new response
        mash.hits.hits.map do |a|
          Hashie::Mash.new(a._source)
        end
      end

      def elasticsearch_client
        self.new(
          host: StretchPants.configuration.elasticsearch_host,
          log: StretchPants.configuration.log_level == :debug,
          trace: StretchPants.configuration.trace_client,
          transport_options: {
            force_post: StretchPants.configuration.force_post
          }
        )
      end
    end

    def perform_request(method, path, params, body)
      method = 'POST' if method == 'GET' and @transport.options[:transport_options][:force_post]
      super
    end
  end
end
