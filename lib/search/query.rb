require 'active_support/core_ext/object/blank'

module StretchPants
  class Search
    class Query

      def self.find index_name, id
        query = { query: { match: { _id: id } } }
        Searcher.perform(index_name, query).pop
      end

      def initialize(index_name, query)
        @index_name = index_name
        @query = query
      end

      def call
        query = {}
        # XXX limit should be size for consistency
        query[:size] = @query.limit if @query.limit.present?
        query[:sort] = @query.sort if @query.sort.present?
        query[:filter] = { and: build_filter_terms(@query.filters) }

        query[:filter][:and] << @query.raw_terms if @query.raw_terms.present?
        query[:query] = @query.query if @query.query.present?

        query.delete(:filter) if query[:filter] == {:and => []}

        results = Searcher.perform @index_name, query

        @query.inclusions.each do |assoc, source_class|
          results.each_with_index do |res, i|
            if id = res.send("#{assoc.to_s}_id")
              klass = Elastic.const_get(source_class.to_s.classify)
              results[i][assoc] = klass.find(id)
            end
          end
        end
        results
      end

      private

      def build_filter_terms(filters)
        filters.map do |filter_type, filter_params|
          filter_params.map do |filter_values|
            filter_klass = StretchPants::Search.const_get(type_to_filter_klass(filter_type))
            filter_klass.new(filter_values).to_h
          end
        end.flatten
      end

      # poor man's camelize
      def type_to_filter_klass(sym)
        sym.to_s.gsub(/(\b|_)([a-z\d]*)/) { "#{$2.capitalize}"  } + "Filter"
      end

    end

  end
end
