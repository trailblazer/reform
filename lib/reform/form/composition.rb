class Reform::Form
  # Automatically creates a Composition object for you when initializing the form.
  module Composition
    def self.included(base)
      base.class_eval do
        extend ClassMethods
      end
    end

    module ClassMethods
      def model_class # DISCUSS: needed?
        rpr = representer_class
        @model_class ||= Class.new(Reform::Composition) do
          map_from rpr
        end
      end

      def property(name, options={})
        super
        delegate options[:on] => :@model
      end
    end

    def initialize(models)
      composition = self.class.model_class.new(models)
      super(composition)
    end

    def to_nested_hash
      model.nested_hash_for(to_hash)  # use composition to compute nested hash.
    end
  end


  module DSL
    include Composition

    def self.included(base)
      warn "[DEPRECATION] Reform::Form: `DSL` is deprecated.  Please use `Composition` instead."

      base.class_eval do
        extend Composition::ClassMethods
      end
    end
  end
end