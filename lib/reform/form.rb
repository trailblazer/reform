module Reform
  class Form < Contract
    twin_representer_class.instance_eval do
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
        # DISCUSS: Populators should be a representable concept?

        # if populator = options.delete(:populate_if_empty)
        if options[:deserializer] == {} # FIXME: hmm. not a fan of this: only add when no other option given?
          options.merge!({populator: Populator::Sync.new(self)})
        end

        if populator = options.delete(:populate_if_empty)
          options.merge!({populator: Populator::IfEmpty.new(populator, self)})
        end

        if populator = options.delete(:populator)
          options[:deserializer].merge!({instance: Populator.new(populator, self)})
          options[:deserializer].merge!({setter: nil}) if options[:collection]
        end

        super
      end
    end
    extend Property


    # TODO: move somewhere else!
    # TODO: make inheritable? and also, there's a lot of noise. shorten.
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


      class IfEmpty < Populator
        def call(fragment, model, *args)
          options = args.last

          if options.binding.array? # FIXME: ifs suck.
            index = args.first
            item = model[index] and return item

            model.insert(index, run!(fragment, options))
          else
            run!(fragment, options)
          end
        end

      private
        # FIXME: replace this with Uber:::V.
        def run!(fragment, options)
          if @user_proc.is_a?(Proc)
            @context.instance_exec(fragment, options.user_options, &@user_proc) # call user block.
          else
            @user_proc.new
          end
        end
      end

      class Sync
        def initialize(context)
          # @context = context
        end

        def call(fragment, model, *args)
          options = args.last

          if options.binding.array? # FIXME: ifs suck.
            index = args.first
            return model[index]
          else
            model
          end
        end
      end
    end # Populator
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
