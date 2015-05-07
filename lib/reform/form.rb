module Reform
  class Form < Contract
    object_representer_class.instance_eval do
      def default_inline_class
        Form
      end
    end

    require "reform/form/validate"
    include Validate # extend Contract#validate with additional behaviour.

    module Property
      # add macro logic, e.g. for :populator.
      def property(name, options={}, &block)
        options[:deserializer] ||= {} # TODO: test ||=.

        # TODO: make this pluggable.
        if populator = options.delete(:populator)
          options[:deserializer].merge!({:instance => Populator.new(populator, self), :setter => nil})
        end

        super
      end
    end
    extend Property


    # TODO: move somewhere else!
    # Implements the :populator option.
    #
    #  populator: -> (fragment, model, options)
    #  populator: -> (fragment, collection, index, options)
    #
    # For collections, the entire collection and the currently deserialised index is passed in.
    class Populator
      include Uber::Callable

      def initialize(user_proc, context)
        @user_proc = user_proc # the actual `populator: ->{}` block from the user, via ::property.
        @context   = context # TODO: execute lambda via Uber:::Option and in form context.
      end

      def call(form, fragment, *args)
        options = args.last

        @user_proc.call(fragment, options.binding.get, *args)
      end
    end
  end

  # class Form_ < Contract
  #   self.representer_class = Reform::Representer.for(:form_class => self)
  #   self.object_representer_class = Reform::ObjectRepresenter.for(:form_class => self)

  #   require "reform/form/validate"
  #   include Validate # extend Contract#validate with additional behaviour.
  #   require "reform/form/sync"
  #   include Sync
  #   require "reform/form/save"
  #   include Save
  #   require "reform/form/prepopulate"
  #   include Prepopulate

  #   require "reform/form/multi_parameter_attributes"
  #   include MultiParameterAttributes # TODO: make features dynamic.

  # private
  #   def aliased_model
  #     # TODO: cache the Expose.from class!
  #     Reform::Expose.from(mapper).new(:model => model)
  #   end


  #   require "reform/form/scalar"
  #   extend Scalar::Property # experimental feature!


  #   # DISCUSS: should that be optional? hooks into #validate, too.
  #   require "reform/form/changed"
  #   register_feature Changed
  #   include Changed
  # end
end
