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


  def sync_models
    sync!
  end
  alias_method :sync, :sync_models

  # reading from fields allows using readers in form for presentation
  # and writers still pass to fields in #validate????
  def sync! # semi-public.
    options = Reform::Representer::Options[:form => self] # options local for this form, only.


    puts "1. sync_hash"
    input = sync_hash(options)
    puts "5. ... input: #{input.inspect}"
    # if aliased_model was a proper Twin, we could do changed? stuff there.

    # setter_module = Class.new(self.class.representer_class)
    # setter_module.send :include, Setter


    puts
    puts "?????? from_hash #{input.inspect}"
    mapper.new(aliased_model).extend(Writer).extend(Setter).from_hash(input) # sync properties to Song.

    model
  end

private
  # API: semi-public.
  module SyncHash
    # This hash goes into the Writer that writes properties back to the model. It only contains "writeable" attributes.
    def sync_hash(options)
      input_representer = mapper.new(fields).extend(InputRepresenter)

      # options.delete(:exclude)
      puts "4. >>>> to_hash #{options}"
      # options[:include] = options[:include] - [:image]
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

      puts "3. --------- #{readonly_fields.inspect}"
      # this must happen in Options
      puts "3b. -------- #{options[:include].inspect}"
      options[:include].delete(:image)

      options.exclude!(readonly_fields)
      puts "3c. @@@@@@@@@ #{options.inspect}"

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

      changed_properties = changed.collect { |k,v| v ? k.to_sym : nil }.compact # scalars.
      changed_properties += mapper.representable_attrs.find_all { |dfn| dfn[:form] }.collect { |dfn| dfn.name.to_sym }

      puts "2. including #{changed_properties.inspect}"
      options.include!(changed_properties)

      super

      # new_hash={}
      # # FIXME: use :include and use this with nested forms!
      # changed_properties.each do |p|
      #   new_hash[p] = h[p]
      # end

      # new_hash
    end
  end
end
