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

    # called after populator: form.deserialize(params)
    # as this only included in the typed pipeline, it's not applied for scalars.
    Deserialize = ->(options) { options[:result].deserialize(options[:fragment]) } # TODO: (result:, fragment:, **o) once we drop 2.0.

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
        # * they are only used in the deserializer.

        populator = Populator::Sync.new(nil)
        if block = definition[:populate_if_empty]
          populator = Populator::IfEmpty.new(block)
        elsif block = definition[:populator]
          populator = Populator.new(block)
        end

        # DISCUSS: allow populators for scalars, too?
        if definition.typed?
          standard_pipeline = [Representable::SkipParse, populator, Deserialize]

          if definition.array?
            pipeline = ->(*) { [Representable::StopOnNotFound, Representable::Collect[*standard_pipeline]] }
          else
            pipeline = ->(*) { [Representable::StopOnNotFound, *standard_pipeline] }
          end


        else
          standard_pipeline = [Representable::SkipParse, Representable::Setter]

          if definition.array?
            pipeline = ->(*) { [Representable::StopOnNotFound, Representable::Collect[*standard_pipeline]] }
          else
            pipeline = ->(*) { [Representable::StopOnNotFound, *standard_pipeline] }
          end
        end

        # the parsing pipeline is now super slim:
        # nested form:       StopOnNotFound, SkipParse, Instance, Deserialize
        # nested collection: StopOnNotFound, [SkipParse, Instance, Deserialize]
        # scalar:            StopOnNotFound, SkipParse, Setter
        # scalar collection: StopOnNotFound, [SkipParse, Setter]
        deserializer_options.merge!(parse_pipeline: pipeline) # TODO: test that Default, etc are NOT RUN.




        # TODO: shouldn't that go into validate?
        if proc = definition[:skip_if]
          proc = Reform::Form::Validate::Skip::AllBlank.new if proc == :all_blank
          deserializer_options.merge!(skip_parse: proc)
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