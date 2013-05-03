class Reform::Form
  module DSL
    def self.included(base)
      base.class_eval do
        extend ClassMethods
      end
    end

    module ClassMethods
      def property(*args)
        representer_class.property(*args)
      end

    #private
      def representer_class
        @representer_class ||= Class.new(Reform::Representer)
      end

      def model_class
        rpr = representer_class
        @model_class ||= Class.new(Reform::Composition) do
          map_from rpr
        end
      end
    end

    def initialize(models)
      composition = self.class.model_class.new(models)
      super(self.class.representer_class, composition)
    end
  end
end