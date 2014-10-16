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
            # FIXME: do we allow options for #sync for nested forms?
          :deserialize => lambda { |object, *| model = object.sync!({}) } # sync! returns the synced model.
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

        # evaluate the :sync block in form context (should we do that everywhere?).
        setter_proc = lambda { |value, options|
          # puts "~~ #{value}~ #{options.user_options.inspect}"

          if options.binding[:sync] == true
            options.user_options[options.binding.name.to_sym].call(value, options)
            next
          end

          options.user_options[:form].instance_exec(value, options, &setter) }
        dfn.merge!(:setter => setter_proc)
      end

      super
    end
  end

  # Transforms form input into what actually gets written to model.
  # output: {title: "Mint Car", hit: <Form>}
  module InputRepresenter
    # receives Representer::Options hash.
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


  def sync_models(options={})
    sync!(options)
  end
  alias_method :sync, :sync_models

  # reading from fields allows using readers in form for presentation
  # and writers still pass to fields in #validate????
  def sync!(options) # semi-public.
    options = Reform::Representer::Options[options.merge(:form => self)] # options local for this form, only.

    input = sync_hash(options)
    # if aliased_model was a proper Twin, we could do changed? stuff there.
    # setter_module = Class.new(self.class.representer_class)
    # setter_module.send :include, Setter

    options.delete(:exclude) # TODO: can we use 2 options?

    mapper.new(aliased_model).extend(Writer).extend(Setter).from_hash(input, options) # sync properties to Song.

    model
  end

private
  # API: semi-public.
  module SyncHash
    # This hash goes into the Writer that writes properties back to the model. It only contains "writeable" attributes.
    def sync_hash(options)
      input_representer = mapper.new(fields).extend(InputRepresenter)
      input_representer.to_hash(options)
    end
  end
  include SyncHash


  # Excludes :virtual properties from #sync in this form.
  module ReadOnly
    def sync_hash(options)
      readonly_fields = mapper.representable_attrs.
        find_all { |dfn| dfn[:virtual] }.
        collect  { |dfn| dfn.name.to_sym }

      options.exclude!(readonly_fields)

      super
    end
  end
  include ReadOnly


  # This will skip unchanged properties in #sync. To use this for all nested form do as follows.
  #
  #   class SongForm < Reform::Form
  #     feature Synd::SkipUnchanged
  module SkipUnchanged
    def sync_hash(options)
      # DISCUSS: we currently don't track if nested forms have changed (only their attributes). that's why i include them all here, which
      # is additional sync work/slightly wrong. solution: allow forms to form.changed? not sure how to do that with collections.
      scalars   = mapper.representable_attrs.find_all{ |dfn| !dfn[:form] }.collect { |dfn| dfn.name }
      unchanged = scalars - changed.keys

      # exclude unchanged scalars, nested forms and changed scalars still go in here!
      options.exclude!(unchanged.map(&:to_sym))
      super
    end
  end
end
