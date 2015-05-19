module Reform
  class Form < Contract
    twin_representer_class.instance_eval do
      def default_inline_class
        Form
      end
    end

    require "reform/form/validate"
    include Validate # extend Contract#validate with additional behaviour.

    require "reform/form/populator"

    module Property
      # add macro logic, e.g. for :populator.
      def property(name, options={}, &block)
        if options[:virtual]
          options[:writeable] = options[:readable] = false # DISCUSS: isn't that like an #option in Twin?
        end

        options[:deserializer] ||= {} # TODO: test ||=.

        # TODO: make this pluggable.
        # DISCUSS: Populators should be a representable concept?

        # Populators
        # * they assign created data, no :setter (hence the name).
        # * they (ab)use :instance, this is why they need to return a twin form.
        # * they are only used in the deserializer.

        if populator = options.delete(:populate_if_empty)
          options[:deserializer].merge!({instance: Populator::IfEmpty.new(populator)})
          options[:deserializer].merge!({setter: nil})
        elsif populator = options.delete(:populator)
          options[:deserializer].merge!({instance: Populator.new(populator)})
          options[:deserializer].merge!({setter: nil}) #if options[:collection] # collections don't need to get re-assigned, they don't change.
        end


        # TODO: shouldn't that go into validate?
        if proc = options.delete(:skip_if)
          proc = Reform::Form::Validate::Skip::AllBlank.new if proc == :all_blank
          options[:deserializer].merge!(skip_parse: proc)
        end


        # default:
        # FIXME: this is, of course, ridiculous and needs a better structuring.
        if (options[:deserializer] == {} || options[:deserializer].keys == [:skip_parse]) && block_given? # FIXME: hmm. not a fan of this: only add when no other option given?
          options[:deserializer].merge!({instance: Populator::Sync.new(nil), setter: nil})
        end

        super
      end
    end
    extend Property


    require "reform/form/multi_parameter_attributes"

    require "disposable/twin/changed"
    feature Disposable::Twin::Changed

    require "disposable/twin/sync"
    feature Disposable::Twin::Sync
  end
end
