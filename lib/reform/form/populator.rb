# Implements the :populator option.
#
#  populator: -> (fragment:, model:, :binding)
#  populator: -> (fragment:, collection:, index:, binding:)
#
# For collections, the entire collection and the currently deserialised index is passed in.
class Reform::Form::Populator
  include Uber::Callable

  def initialize(user_proc)
    @user_proc = user_proc # the actual `populator: ->{}` block from the user, via ::property.
    @value     = Uber::Options::Value.new(user_proc) # we can now process Callable, procs, :symbol.
  end

  def call(options)
    model = options[:binding].get
    twin  = call!(options.merge(model: model, collection: model))

    return twin if twin == Representable::Pipeline::Stop

    # this kinda sucks. the proc may call self.composer = Artist.new, but there's no way we can
    # return the twin instead of the model from the #composer= setter.
    twin = options[:binding].get unless options[:binding].array?

    # we always need to return a twin/form here so we can call nested.deserialize().
    handle_fail(twin, options)

    twin
  end

private
  def call!(options)
    # FIXME: use U:::Value.
    form = options[:binding].represented
    deprecate_positional_args(form, @user_proc, options) do
      form.instance_exec(options, &@user_proc)
    end
  end

  def handle_fail(twin, options)
    raise "[Reform] Your :populator did not return a Reform::Form instance for `#{options[:binding].name}`." if options[:binding][:twin] && !twin.is_a?(Reform::Form)
  end

  def deprecate_positional_args(form, proc, options) # TODO: remove in 2.2.
    arity = proc.is_a?(Symbol) ? form.method(proc).arity : proc.arity
    return yield if arity == 1
    warn "[Reform] Positional arguments for :populator and friends are deprecated. Please use ->(options) and enjoy the rest of your day. Learn more at http://trailblazerb.org/gems/reform/upgrading-guide.html#to-21"
    args = []
    args <<  options[:index] if  options[:index]
    args << options[:representable_options]
    form.instance_exec(options[:fragment], options[:model], *args, &proc)
  end


  class IfEmpty < self # Populator
    def call!(options)
      binding, twin, index, fragment = options[:binding], options[:model], options[:index], options[:fragment] # TODO: remove once we drop 2.0.
      form = binding.represented

      if binding.array?
        item = twin.original[index] and return item

        twin.insert(index, run!(form, fragment, options)) # form.songs.insert(Song.new)
      else
        return if twin

        form.send(binding.setter, run!(form, fragment, options)) # form.artist=(Artist.new)
      end
    end

  private
    def run!(form, fragment, options)
      return @user_proc.new if @user_proc.is_a?(Class) # handle populate_if_empty: Class. this excludes using Callables, though.

      deprecate_positional_args(form, @user_proc, options) do
        @value.(form, options)
      end
    end

    def deprecate_positional_args(form, proc, options) # TODO: remove in 2.2.
      arity = proc.is_a?(Symbol) ? form.method(proc).arity : proc.arity
      return yield if arity == 1
      warn "[Reform] Positional arguments for :prepopulate and friends are deprecated. Please use ->(options) and enjoy the rest of your day. Learn more at http://trailblazerb.org/gems/reform/upgrading-guide.html#to-21"

      @value.(form, options[:fragment], options[:binding].user_options)
    end

  end

  # Sync (default) blindly grabs the corresponding form twin and returns it. This might imply that nil is returned,
  # and in turn #validate! is called on nil.
  class Sync < self
    def call!(options)
      if options[:binding].array?
        return options[:model][options[:index]]
      else
        options[:model]
      end
    end
  end

  # This function is added to the pipeline the deserializer uses. It marks that this
  # property has a populator and simply delegates the entire logic to the form.
  class External
    def call(options)
      options[:binding].represented.schema.representable_attrs.
        get(options[:binding].name)[:internal_populator].(options)
    end
  end
end