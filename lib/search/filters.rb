module StretchPants
  class Search

    class Filter
      def initialize(terms=[])
        @terms = terms
      end

      def to_h
        raise NotImplementedError, 'must be implemented'
      end
    end

    class TermFilter < Filter
      def to_h
        filter_type = (@terms.values[0].is_a? Enumerable) ? :in : :term
        { filter_type => @terms }
      end
    end

    class RangeFilter < Filter
      def to_h
        { :range => @terms }
      end
    end

    class NumericRangeFilter < Filter
      def to_h
        { :numeric_range => @terms }
      end
    end

    class ExistsFilter < Filter
      def to_h
        { :exists => { :field => @terms.keys.pop } }
      end
    end

    class MissingFilter < Filter
      def to_h
        { :missing => { :field => @terms.keys.pop } }
      end
    end

    class NotTermFilter < Filter
      def to_h
        termfilter = TermFilter.new(@terms)
        { not: termfilter.to_h }
      end
    end

  end
end
