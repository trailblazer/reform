# Implements the :populator option.
#
#  populator: -> (fragment:, model:, :binding)
#  populator: -> (fragment:, collection:, index:, binding:)
#
# For collections, the entire collection and the currently deserialised index is passed in.
class Reform::Form::Populator
  def initialize(user_proc)
    @user_proc = user_proc # the actual `populator: ->{}` block from the user, via ::property.
    @value     = Declarative::Option(user_proc, instance_exec: true, callable: Object) # we can now process Callable, procs, :symbol.
  end

  def call(input, options)
    model = get(options)
    twin  = call!(options.merge(model: model, collection: model))

    return twin if twin == Representable::Pipeline::Stop

    # this kinda sucks. the proc may call self.composer = Artist.new, but there's no way we can
    # return the twin instead of the model from the #composer= setter.
    twin = get(options) unless options[:binding].array?

    # we always need to return a twin/form here so we can call nested.deserialize().
    handle_fail(twin, options)

    twin
  end

  private

  def call!(options)
    form = options[:represented]
    @value.(form, options) # Declarative::Option call.
  end

  def handle_fail(twin, options)
    raise "[Reform] Your :populator did not return a Reform::Form instance for `#{options[:binding].name}`." if options[:binding][:nested] && !twin.is_a?(Reform::Form)
  end

  def get(options)
    Representable::GetValue.(nil, options)
  end

  class IfEmpty < self # Populator
    def call!(options)
      binding, twin, index, fragment = options[:binding], options[:model], options[:index], options[:fragment] # TODO: remove once we drop 2.0.
      form = options[:represented]

      if binding.array?
        item = twin.original[index] and return item

        new_index = [index, twin.count].min # prevents nil items with initially empty/smaller collections and :skip_if's.
        # this means the fragment index and populated nested form index might be different.

        twin.insert(new_index, run!(form, fragment, options)) # form.songs.insert(Song.new)
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

      @value.(form, options[:fragment], options[:user_options])
    end
  end

  # Sync (default) blindly grabs the corresponding form twin and returns it. This might imply that nil is returned,
  # and in turn #validate! is called on nil.
  class Sync < self
    def call!(options)
      return options[:model][options[:index]] if options[:binding].array?
      options[:model]
    end
  end

  # This function is added to the deserializer's pipeline.
  #
  # When deserializing, the representer will call this function and thereby delegate the
  # entire population process to the form. The form's :internal_populator will run its
  # :populator option function and return the new/existing form instance.
  # The deserializing representer will then continue on that returned form.
  #
  # Goal of this indirection is to leave all population logic in the form, while the
  # representer really just traverses an incoming document and dispatches business logic
  # (which population is) to the form.
  class External
    def call(input, options)
      options[:represented].class.definitions
                           .get(options[:binding][:name])[:internal_populator].(input, options)
    end
  end
end
