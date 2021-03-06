module StretchPants
  class Search
    class Base
      class << self
        def scoped &b
          Scope.chainable do |scope_klass|
            scope_klass.class_eval &b
          end
        end

        def find(id)
          Query.find(self.index_name, id)
        end

        def method_missing method, *args, &block
          if Scope.chainables.include? method
            Scope.new(self).send(method, *args)
          else
            super
          end
        end

        def respond_to? method, include_all=false
          Scope.chainables.include?(method) or super
        end

        def index_name
          "#{self.to_s.split('::').join('_')}_#{StretchPants.configuration.index_env}"
        end
      end
    end
  end
end
