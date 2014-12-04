# #sync!
#   1. assign scalars to model (respecting virtual, excluded attributes)
#   2. call sync! on nested
module Reform::Form::Sync
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

    options.delete(:exclude) # TODO: can we use 2 options?

    dynamic_sync_representer.new(aliased_model).from_hash(input, options) # sync properties to Song.

    model
  end

private

  # Transforms form input into what actually gets written to model.
  # output: {title: "Mint Car", hit: <Form>}
  def input_representer
    self.class.representer(:input, :all => true) do |dfn|
      if dfn[:form]
        dfn.merge!(
          :representable  => false,
          :prepare        => lambda { |obj, *| obj },
        )
      else
        dfn.merge!(:render_nil => true) # do sync nil values back to the model for scalars.
      end
    end
  end

  # Writes input to model.
  def sync_representer
    self.class.representer(:sync, :all => true) do |dfn|
      if dfn[:form]
        dfn.merge!(
          :instance     => lambda { |fragment, *| fragment }, # use model's nested property for syncing.
            # FIXME: do we allow options for #sync for nested forms?
          :deserialize => lambda { |object, *| model = object.sync!({}) } # sync! returns the synced model.
          # representable's :setter will do collection=([..]) or property=(..) for us on the model.
        )
      end
    end
  end

  # This representer inherits from sync_representer and add functionality on top of that.
  # It allows running custom dynamic blocks for properties when syncing.
  def dynamic_sync_representer
    self.class.representer(:dynamic_sync, superclass: sync_representer, :all => true) do |dfn|
      next unless setter = dfn[:sync]

      setter_proc = lambda do |value, options|
        if options.binding[:sync] == true # sync: true will call the runtime lambda from the options hash.
          options.user_options[options.binding.name.to_sym].call(value, options)
          next
        end

        # evaluate the :sync block in form context (should we do that everywhere?).
        options.user_options[:form].instance_exec(value, options, &setter)
      end

      dfn.merge!(:setter => setter_proc)
    end
  end


  # API: semi-public.
  module SyncHash
    # This hash goes into the Writer that writes properties back to the model. It only contains "writeable" attributes.
    def sync_hash(options)
      input_representer.new(fields).to_hash(options)
    end
  end
  include SyncHash


  # Excludes :virtual and readonly properties from #sync in this form.
  module Writeable
    def sync_hash(options)
      readonly_fields = mapper.fields { |dfn| dfn[:_writeable] == false }

      options.exclude!(readonly_fields.map(&:to_sym))

      super
    end
  end
  include Writeable


  # This will skip unchanged properties in #sync. To use this for all nested form do as follows.
  #
  #   class SongForm < Reform::Form
  #     feature Synd::SkipUnchanged
  module SkipUnchanged
    def sync_hash(options)
      # DISCUSS: we currently don't track if nested forms have changed (only their attributes). that's why i include them all here, which
      # is additional sync work/slightly wrong. solution: allow forms to form.changed? not sure how to do that with collections.
      scalars   = mapper.fields { |dfn| !dfn[:form] }
      unchanged = scalars - changed.keys

      # exclude unchanged scalars, nested forms and changed scalars still go in here!
      options.exclude!(unchanged.map(&:to_sym))
      super
    end
  end
end
