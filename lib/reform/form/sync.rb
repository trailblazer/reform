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
          :deserialize => lambda { |object, *| model = object.sync! } # sync! returns the synced model.
          # representable's :setter will do collection=([..]) or property=(..) for us on the model.
        )
      end

      super
    end
  end

  module Setter
    def from_hash(*)
      clone_config!

      representable_attrs.each do |dfn|
        next unless setter = dfn[:sync]

        setter_proc = lambda { |value, options| options.user_options[:form].instance_exec(value, options, &setter) }
        dfn.merge!(:setter => setter_proc)
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


  def sync_models
    sync!
  end
  alias_method :sync, :sync_models

  # reading from fields allows using readers in form for presentation
  # and writers still pass to fields in #validate????
  def sync! # semi-public.
    input = syncable_hash

    # if aliased_model was a proper Twin, we could do changed? stuff there.

    # setter_module = Class.new(self.class.representer_class)
    # setter_module.send :include, Setter

    mapper.new(aliased_model).extend(Writer).extend(Setter).from_hash(input, :form => self) # sync properties to Song.

    model
  end

private
  def syncable_hash(options={})
    input_representer = mapper.new(fields).extend(InputRepresenter)

    input_representer.to_hash(options)
  end

  # This will skip unchanged properties in #sync. To use this for all nested form do as follows.
  #
  #   class SongForm < Reform::Form
  #     feature Synd::SkipUnchanged
  module SkipUnchanged
    def syncable_hash
      # DISCUSS: we currently don't track if nested forms have changed (only their attributes). that's why i include them all here, which
      # is additional sync work/slightly wrong. solution: allow forms to form.changed? not sure how to do that with collections.

      changed_properties = changed.collect { |k,v| v ? k : nil }.compact # scalars.
      changed_properties += mapper.representable_attrs.find_all { |dfn| dfn[:form] }.collect { |dfn| dfn.name }

      h=super(:include => changed_properties)

      new_hash={}
      # FIXME: use :include and use this with nested forms!
      changed_properties.each do |p|
        new_hash[p] = h[p]
      end

      new_hash
    end
  end
end
