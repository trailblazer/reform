require 'forwardable'
require 'uber/inheritable_attr'
require 'uber/delegates'

module Reform
  # Gives you a DSL for defining the object structure and its validations.
  require "disposable/twin"
  require "disposable/twin/setup"
  class Contract < Disposable::Twin
    require "disposable/twin/composition" # Expose.
    include Expose

    feature Setup
    feature Setup::SkipSetter

    extend Uber::Delegates

    representer_class.instance_eval do
      def default_inline_class
        Contract
      end
    end

    def self.property(name, options={}, &block)
      if twin = options.delete(:form)
        options[:twin] = twin
      end

      if validates_options = options[:validates]
        validates name, validates_options.dup # .dup for RAils 3.x because it's retarded.
      end

      super
    end

    # FIXME: test me.
    def self.properties(*args)
      options = args.extract_options!
      args.each { |name| property(name, options) }
    end

    # FIXME: make AM optional.
    require 'active_model'
    include ActiveModel::Validations

    require 'reform/contract/validate'
    include Reform::Contract::Validate

    require 'reform/contract/errors'

  private
    # DISCUSS: can we achieve that somehow via features in build_inline?
    # TODO: check out if that is needed with Lotus::Validations and make it a AM feature.
    def self.process_inline!(mod, definition)
      _name = definition.name
      mod.instance_eval do
        @_name = _name.singularize.camelize
        def name # this adds Form::name for AM::Validations and I18N. i know it's retarded.
          # something weird happens here: somewhere in Rails, this creates a constant (e.g. User). if this name doesn't represent a valid
          # constant, the reloading in dev will fail with weird messages. i'm not sure if we should just get rid of Rails validations etc.
          # or if i should look into this?
          @_name
        end
      end
    end


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
