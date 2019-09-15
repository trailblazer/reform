module Reform
  # Define your form structure and its validations. Instantiate it with a model,
  # and then +validate+ this object graph.
  class Contract < Disposable::Twin
    require "reform/contract/custom_error"
    require "disposable/twin/composition" # Expose.
    include Expose

    feature Setup
    feature Setup::SkipSetter
    feature Default

    def self.default_nested_class
      Contract
    end

    def self.property(name, options = {}, &block)
      if twin = options.delete(:form)
        options[:twin] = twin
      end

      if validates_options = options[:validates]
        validates name, validates_options
      end

      super
    end

    def self.properties(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      args.each { |name| property(name, options.dup) }
    end

    require "reform/result"
    require "reform/contract/validate"
    include Reform::Contract::Validate

    require "reform/validation"
    include Reform::Validation # ::validates and #valid?

    # FIXME: this is only for #to_nested_hash, #sync shouldn't be part of Contract.
    require "disposable/twin/sync"
    include Disposable::Twin::Sync

    private

    # DISCUSS: separate file?
    module Readonly
      def readonly?(name)
        options_for(name)[:writeable] == false
      end

      def options_for(name)
        self.class.options_for(name)
      end
    end

    def self.options_for(name)
      definitions.get(name)
    end
    include Readonly

    def self.clone # TODO: test. THIS IS ONLY FOR Trailblazer when contract gets cloned in suboperation.
      Class.new(self)
    end
  end
end
