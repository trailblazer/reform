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

  def call(form, fragment, *args)
    options = args.last

    # FIXME: the optional index parameter SUCKS.
    twin = call!(form, fragment, options.binding.get, *args)

    # this kinda sucks. the proc may call self.composer = Artist.new, but there's no way we can
    # return the twin instead of the model from the #composer= setter.
    twin = options.binding.get unless options.binding.array?

    # since Populator#call is invoked as :instance, we always need to return a twin/form here.
    handle_fail(twin, options)

    twin
  end

private
  # DISCUSS: this signature could change soon.
  # FIXME: the optional index parameter SUCKS.
  def call!(form, fragment, model, *args)
    # FIXME: use U:::Value.
    form.instance_exec(fragment, model, *args, &@user_proc)
  end

  def handle_fail(twin, options)
    raise "[Reform] Your :populator did not return a Reform::Form instance for `#{options.binding.name}`." if options.binding[:twin] && !twin.is_a?(Reform::Form)
  end


  class IfEmpty < self # Populator
    # FIXME: the optional index parameter SUCKS.
    def call!(form, fragment, twin, *args)
      options = args.last

      if options.binding.array? # FIXME: ifs suck.
        index = args.first
        item = twin.original[index] and return item

        twin.insert(index, run!(form, fragment, options)) # form.songs.insert(Song.new)
      else
        return if twin

        form.send(options.binding.setter, run!(form, fragment, options)) # form.artist=(Artist.new)
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
    def call!(form, fragment, model, *args)
      options = args.last

      if options.binding.array?
        index = args.first
        return model[index]
      else
        model
      end
    end
  end
end