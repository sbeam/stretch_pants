require 'ostruct'
require 'active_support/core_ext/hash/deep_merge'

module StretchPants
  class Search

    class Scope
      include Enumerable

      [:[], :blank?, :in_groups_of, :first, :each, :inspect].each do |method|
        define_method :method do
          to_a
        end
      end

      @chainables = []

      class << self
        attr_reader :chainables

        def chainable
          old_methods = self.instance_methods(false)
          yield self
          (self.instance_methods(false) - old_methods).each do |method|
            method_without_chains = "#{method.to_s}_with_reset".to_sym
            alias_method method_without_chains, method

            define_method method do |*args|
              @memo_query_results = nil
              self.send method_without_chains, *args
              self
            end
            @chainables << method
          end
        end
      end

      def initialize klass
        @base = klass
        @index = klass.index_name
        @query = OpenStruct.new raw_terms: {},
                                filters: {},
                                sort: [],
                                limit: nil,
                                inclusions: {},
                                query: {}
      end

      def to_a
        @memo_query_results ||= Query.new(@index, @query).call
      end

      chainable do

        def query query
          @query.query.deep_merge! query
        end

        def raw_terms terms
          @query.raw_terms.deep_merge! terms
        end

        def filter *args
          type = args[0].is_a?(Symbol) ? args.shift : :term
          args.pop.each_pair do |field, value|
            (@query.filters[type] ||= []) << {field => value}
          end
        end

        def range field, params
          filter :range, { field => params }
        end

        def limit to
          @query.limit = to
        end

        def sort by
          @query.sort << by
        end

        def including associations
          @query.inclusions.merge! associations
        end

        def exists field
          filter :exists, field => nil
        end

        def missing field
          filter :missing, field => nil
        end

        def not_filter terms
          filter :not_term, terms
        end

      end

      def method_missing method, *args, &block
        if @base.respond_to? method
          @base.send method, *args
        end
      end

      def respond_to_missing? method
        super || @base.respond_to?(method)
      end
    end

  end
end
