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
        if options[:virtual]
          options[:writeable] = options[:readable] = false # DISCUSS: isn't that like an #option in Twin?
        end

        options[:deserializer] ||= {} # TODO: test ||=.

        # TODO: make this pluggable.
        # DISCUSS: Populators should be a representable concept?

        if populator = options.delete(:populate_if_empty)
          options.merge!({populator: Populator::IfEmpty.new(populator)})
        end

        if populator = options.delete(:populator)
          options[:deserializer].merge!({instance: Populator.new(populator)})
          options[:deserializer].merge!({setter: nil}) #if options[:collection] # collections don't need to get re-assigned, they don't change.
        end


        # TODO: shouldn't that go into validate?
        if proc = options.delete(:skip_if)
          proc = Reform::Form::Validate::Skip::AllBlank.new if proc == :all_blank
          options[:deserializer].merge!(skip_parse: proc)
        end


        # default:
        # FIXME: this is, of course, ridiculous and needs a better structuring.
        if (options[:deserializer] == {} or options[:deserializer].keys == [:skip_parse]) and block_given? # FIXME: hmm. not a fan of this: only add when no other option given?
          options[:deserializer].merge!({instance: Populator.new(Populator::Sync.new), setter: nil})
        end

        super
      end
    end
    extend Property




    # TODO: move somewhere else!
    # TODO: make inheritable? and also, there's a lot of noise. shorten.
    # Implements the :populator option.
    #
    #  populator: -> (fragment, twin, options)
    #  populator: -> (fragment, collection[twin], index, options)
    #
    # For collections, the entire collection and the currently deserialised index is passed in.
    class Populator
      include Uber::Callable

      def initialize(user_proc)
        @user_proc = user_proc # the actual `populator: ->{}` block from the user, via ::property.
      end

      def call(form, fragment, *args)
        options = args.last

        # FIXME: use U:::Value.
        twin = form.instance_exec(fragment, options.binding.get, *args, &@user_proc) if @user_proc.is_a?(Proc)
        twin = @user_proc.call(form, fragment, options.binding.get, *args)

        # this kinda sucks. the proc may call self.composer = Artist.new, but there's no way we can
        # return the twin instead of the model from the #composer= setter.
        twin = options.binding.get unless options.binding.array?

        # DICSUSS: do we need this?
        raise "[Reform] Your :populator did not return a Reform::Form instance." if options.binding[:twin] && !twin.is_a?(Reform::Form)

        twin
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


    require "disposable/twin/changed"
    feature Disposable::Twin::Changed

    require "disposable/twin/sync"
    feature Disposable::Twin::Sync
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
end
