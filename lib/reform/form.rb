require "disposable/twin/schema"

module Reform
  class Form < Contract
    representer_class.instance_eval do
      def default_inline_class
        Form
      end
    end

    require "reform/form/validate"
    include Validate # override Contract#validate with additional behaviour.

    require "reform/form/populator"

    module Property
      # Add macro logic, e.g. for :populator.
      # TODO: This will be re-structured once Declarative allows it.
      def property(name, options={}, &block)
        if deserializer = options[:deserializer] # this means someone is explicitly specifying :deserializer.
          options[:deserializer] = Representable::Cloneable::Hash[deserializer]
        end

        definition = super # let representable sort out inheriting of properties, and so on.
        definition.merge!(deserializer: Representable::Cloneable::Hash.new) unless definition[:deserializer] # always keep :deserializer per property.

        deserializer_options = definition[:deserializer]

        # Populators
        # * they assign created data, no :setter (hence the name).
        # * they (ab)use :instance, this is why they need to return a twin form.
        # * they are only used in the deserializer.
        if populator = options.delete(:populate_if_empty)
          deserializer_options.merge!({instance: Populator::IfEmpty.new(populator)})
          deserializer_options.merge!({setter: nil})
        elsif populator = options.delete(:populator)
          deserializer_options.merge!({instance: Populator.new(populator)})
          deserializer_options.merge!({setter: nil})
        end


        # TODO: shouldn't that go into validate?
        if proc = options.delete(:skip_if)
          proc = Reform::Form::Validate::Skip::AllBlank.new if proc == :all_blank

          deserializer_options.merge!(skip_parse: proc)
        end

        # default:
        # add Sync populator to nested forms.
        # FIXME: this is, of course, ridiculous and needs a better structuring.
        if (deserializer_options == {} || deserializer_options.keys == [:skip_parse]) && definition[:twin] && !options[:inherit] # FIXME: hmm. not a fan of this: only add when no other option given?
          deserializer_options.merge!(instance: Populator::Sync.new(nil), setter: nil)
        end

        # per default, everything should be writeable for the deserializer (we're only writing on the form). however, allow turning it off.
        deserializer_options.merge!(writeable: true) unless deserializer_options.has_key?(:writeable)

        definition
      end
    end
    extend Property


    require "reform/form/multi_parameter_attributes"

    require "disposable/twin/changed"
    feature Disposable::Twin::Changed

    require "disposable/twin/sync"
    feature Disposable::Twin::Sync
    feature Disposable::Twin::Sync::SkipGetter

    require "disposable/twin/save"
    feature Disposable::Twin::Save

    require "reform/form/prepopulate"
    include Prepopulate
  end
end