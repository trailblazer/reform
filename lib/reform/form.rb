module Reform
  class Form < Contract
    def self.default_nested_class
      Form
    end

    require "reform/form/validate"
    include Validate # override Contract#validate with additional behaviour.

    require "reform/form/populator"

    # called after populator: form.deserialize(params)
    # as this only included in the typed pipeline, it's not applied for scalars.
    Deserialize = ->(input, options) { input.deserialize(options[:fragment]) } # TODO: (result:, fragment:, **o) once we drop 2.0.

    module Property
      # Add macro logic, e.g. for :populator.
      # TODO: This will be re-structured once Declarative allows it.
      def property(name, options={}, &block)
        if deserializer = options[:deserializer] # this means someone is explicitly specifying :deserializer.
          options[:deserializer] = deserializer
        end

        definition = super # let representable sort out inheriting of properties, and so on.
        definition.merge!(deserializer: {}) unless definition[:deserializer] # always keep :deserializer per property.

        deserializer_options = definition[:deserializer]

        # Populators
        internal_populator = Populator::Sync.new(nil)
        if block = definition[:populate_if_empty]
          internal_populator = Populator::IfEmpty.new(block)
        end
        if block = definition[:populator] # populator wins over populate_if_empty when :inherit
          internal_populator = Populator.new(block)
        end
        definition.merge!(internal_populator: internal_populator) unless options[:internal_populator]
        external_populator = Populator::External.new



        if definition[:nested]
          standard_pipeline = [Representable::SkipParse, Representable::AssignFragment, external_populator, Deserialize]

          if definition[:collection]
            pipeline =  [Representable::AssignName, Representable::ReadFragment, Representable::StopOnNotFound, Representable::Collect[*standard_pipeline]]
          else
            pipeline =  [Representable::AssignName, Representable::ReadFragment, Representable::StopOnNotFound, *standard_pipeline]
          end


        else
          setter = options[:populator] ? external_populator : Representable::Set # FIXME: this won't work with property :name, inherit: true (where there is a populator set already).
          standard_pipeline = [Representable::SkipParse, setter]

          if definition[:collection]
            pipeline =  [Representable::AssignName, Representable::ReadFragment, Representable::StopOnNotFound, Representable::AssignFragment, Representable::Collect[*standard_pipeline]]
          else
            pipeline =  [Representable::AssignName, Representable::ReadFragment, Representable::StopOnNotFound, Representable::AssignFragment, *standard_pipeline]
          end
        end
        pipeline = [Representable::Stop] if deserializer_options[:writeable]==false || definition[:deserializer_options]&&definition[:deserializer_options][:writeable]==false # TODO: use better API from representable.



        deserializer_options.merge!(parse_pipeline: ->(*) { Representable::Pipeline[*pipeline] }) # TODO: test that Default, etc are NOT RUN.

        if proc = definition[:skip_if]
          proc = Reform::Form::Validate::Skip::AllBlank.new if proc == :all_blank
          deserializer_options.merge!(skip_parse: proc) # TODO: same with skip_parse ==> External
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