module StretchPants
  class Search < Elasticsearch::Transport::Client

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
        self.new host: configatron.core.search.es_url,
          log: Rails.env.development?,
          trace: Rails.env.development?,
          transport_options: {
            force_post: (configatron.core.search.es_url !~ /:9200\b/)  # using a proxy that is allergic to GETs?
          }
      end
    end

    def perform_request(method, path, params, body)
      method = 'POST' if method == 'GET' and @transport.options[:transport_options][:force_post]
      super
    end

  end

end
