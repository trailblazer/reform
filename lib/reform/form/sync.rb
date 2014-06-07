# #sync!
#   1. assign scalars to model (respecting virtual, excluded attributes)
#   2. call sync! on nested
module Reform::Form::Sync
  # Mechanics for writing input to model.
  # Writes input to model.
  module Writer
    def from_hash(*)
      # process output from InputRepresenter {title: "Mint Car", hit: <Form>}
      # and just call sync! on nested forms.
      nested_forms do |attr|
        attr.merge!(
          :instance     => lambda { |fragment, *| fragment },
          :deserialize => lambda { |object, *| object.sync! },
          :setter => lambda { |*| } # don't write hit=<Form>.
        )
      end

      super
    end
  end

  # Transforms form input into what actually gets written to model.
  # output: {title: "Mint Car", hit: <Form>}
  module InputRepresenter
    include Reform::Representer::WithOptions
    # TODO: make dynamic.
    include Reform::Form::EmptyAttributesOptions
    include Reform::Form::ReadonlyAttributesOptions

    def to_hash(*)
      nested_forms do |attr|
        attr.merge!(
          :representable  => false,
          :prepare        => lambda { |obj, *| obj }
        )

      end

      super
    end
  end


### TODO: add ToHash with :prepare => lambda { |form, args| form },

  def sync_models
    sync!
  end
  alias_method :sync, :sync_models

  # reading from fields allows using readers in form for presentation
  # and writers still pass to fields in #validate????
  def sync! # semi-public.
    source = deprecate_potential_readers_used_in_sync_or_save(fields) # TODO: remove in 1.1.

    input_representer = mapper.new(source).extend(InputRepresenter) # FIXME: take values from self.fields!

    input = input_representer.to_hash

    mapper.new(aliased_model).extend(Writer).from_hash(input)
  end

  def deprecate_potential_readers_used_in_sync_or_save(fields) # TODO: remove in 1.1.
    readers = []

    mapper.representable_attrs.each do |definition|
      return fields if definition[:presentation_accessors]

      name = definition.name
      next if method(name).source_location.inspect =~ /forwardable/ # defined by Reform, not overridden by user.

      readers << name
    end
    return fields if readers.size == 0

    warn "[Reform] Deprecation: You're overriding the following readers: #{readers.join(', ')}. In Reform 1.1, those readers will be used for presentation in the view, only. In case you are using the readers deliberately to modify incoming data for #save or #sync: this won't work anymore. If you just use the custom readers in the form view, add `presentation_accessors: true` to a property to suppress this message and use the new behaviour."

    self # old mode
  end
  def deprecate_potential_writers_used_in_validate(fields) # TODO: remove in 1.1.
    readers = []

    mapper.representable_attrs.each do |definition|
      return fields if definition[:presentation_accessors]

      name = definition.setter
      next if method(name).source_location.inspect =~ /forwardable/ # defined by Reform, not overridden by user.

      readers << name
    end
    return fields if readers.size == 0

    warn "[Reform] Deprecation: You're overriding the following writers: #{readers.join(', ')}. In Reform 1.1, those writers will be used for presentation in the view, only. In case you are using the writers deliberately to modify incoming data for #setup or #validate: this won't work anymore.  Add `presentation_accessors: true` to a property to suppress this message and use the new behaviour."

    self # old mode
  end
end
