require "uber/inheritable_attr"
require "disposable/twin"
require "disposable/twin/setup"
require "disposable/twin/default"

module Reform
  # Define your form structure and its validations. Instantiate it with a model,
  # and then +validate+ this object graph.
  class Contract < Disposable::Twin
    require "disposable/twin/composition" # Expose.
    include Expose

    feature Setup
    feature Setup::SkipSetter
    feature Default

    representer_class.instance_eval do
      def default_inline_class
        Contract
      end
    end

    def self.property(name, options={}, &block)
      if twin = options.delete(:form)
        options[:twin] = twin
      end

      options[:pass_options] = true

      if validates_options = options[:validates]
        validates name, validates_options.dup # .dup for RAils 3.x.
      end

      super
    end

    # FIXME: test me.
    def self.properties(*args)
      options = args.extract_options!
      args.each { |name| property(name, options.dup) }
    end

    require 'reform/contract/validate'
    include Reform::Contract::Validate


    module ValidatesWarning
      def validates(*)
        raise "[Reform] Please include either Reform::Form::ActiveModel::Validations or Reform::Form::Lotus in your form class."
      end
    end
    extend ValidatesWarning

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
      representer_class.representable_attrs.get(name)
    end
    include Readonly


    def self.clone # TODO: test. THIS IS ONLY FOR Trailblazer when contract gets cloned in suboperation.
      Class.new(self)
    end

    require "reform/schema"
    extend Reform::Schema
  end
end
