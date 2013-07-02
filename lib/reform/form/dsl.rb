class Reform::Form
  # Automatically creates a Composition object for you when initializing the form.
  module DSL
    def self.included(base)
      base.class_eval do
        extend ClassMethods
      end
    end

    module ClassMethods
      def model_class
        rpr = representer_class
        @model_class ||= Class.new(Reform::Composition) do
          map_from rpr
        end
      end
    end

    def initialize(models)
      composition = self.class.model_class.new(models)
      super(composition)
    end
  end
end