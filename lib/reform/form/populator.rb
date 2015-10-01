# Implements the :populator option.
#
#  populator: -> (fragment, twin, options)
#  populator: -> (fragment, collection[twin], index, options)
#
# For collections, the entire collection and the currently deserialised index is passed in.
class Reform::Form::Populator
  include Uber::Callable

  def initialize(user_proc)
    @user_proc = user_proc # the actual `populator: ->{}` block from the user, via ::property.
    @value     = Uber::Options::Value.new(user_proc) # we can now process Callable, procs, :symbol.
  end

  def call(options)
    twin = call!(options.merge(model: options[:binding].get))

    return twin if twin == Representable::Pipeline::Stop

    # this kinda sucks. the proc may call self.composer = Artist.new, but there's no way we can
    # return the twin instead of the model from the #composer= setter.
    twin = options[:binding].get unless options[:binding].array?

    # since Populator#call is invoked as :instance, we always need to return a twin/form here.
    handle_fail(twin, options)

    twin
  end

private
  # DISCUSS: this signature could change soon.
  # FIXME: the optional index parameter SUCKS.
  def call!(options)
    # TODO: deprecate old API.
    args = []
    args <<  options[:index] if  options[:index]
    args << options[:representable_options]
    # FIXME: use U:::Value.

    # FIXME: deprecate old style positional arguments.

    options[:binding].represented.instance_exec(options[:fragment], options[:model], *args, &@user_proc)
  end

  def handle_fail(twin, options)
    raise "[Reform] Your :populator did not return a Reform::Form instance for `#{options[:binding].name}`." if options[:binding][:twin] && !twin.is_a?(Reform::Form)
  end


  class IfEmpty < self # Populator
    def call!(options)
      binding, twin, index, fragment = options[:binding], options[:model], options[:index], options[:fragment] # TODO: remove once we drop 2.0.

      form = binding.represented

      if binding.array? # FIXME: ifs suck.
        item = twin.original[index] and return item

        twin.insert(index, run!(form, fragment, options[:representable_options])) # form.songs.insert(Song.new)
      else
        return if twin

        form.send(binding.setter, run!(form, fragment, options[:representable_options])) # form.artist=(Artist.new)
      end
    end

  private
    def run!(form, fragment, options)
      return @user_proc.new if @user_proc.is_a?(Class) # handle populate_if_empty: Class. this excludes using Callables, though.

      @value.evaluate(form, fragment, options.user_options)
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
end