module Reform
  class Form < Contract
    class InvalidOptionsCombinationError < StandardError; end

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
      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def property(name, options = {}, &block)
        if (options.keys & %i[skip_if populator]).size == 2
          raise InvalidOptionsCombinationError.new(
            "[Reform] #{self}:property:#{name} Do not use skip_if and populator together, use populator with skip! instead"
          )
        end

        # if composition and inherited we also need this setting
        # to correctly inherit modules
        options[:_inherited] = options[:inherit] if options.key?(:on) && options.key?(:inherit)

        if options.key?(:parse)
          options[:deserializer] ||= {}
          options[:deserializer][:writeable] = options.delete(:parse)
        end

        options[:writeable] ||= options.delete(:writable) if options.key?(:writable)

        # for virtual collection we need at least to have the collection equal to [] to
        # avoid issue when the populator
        if (options.keys & %i[collection virtual]).size == 2
          options = { default: [] }.merge(options)
        end

        definition = super # letdisposable and declarative gems sort out inheriting of properties, and so on.
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

        # always compute a parse_pipeline for each property of the deserializer and inject it via :parse_pipeline.
        # first, letrepresentable compute the pipeline functions by invoking #parse_functions.
        if definition[:nested]
          parse_pipeline = ->(input, opts) do
            functions = opts[:binding].send(:parse_functions)
            pipeline  = Representable::Pipeline[*functions] # Pipeline[StopOnExcluded, AssignName, ReadFragment, StopOnNotFound, OverwriteOnNil, Collect[#<Representable::Function::CreateObject:0xa6148ec>, #<Representable::Function::Decorate:0xa6148b0>, Deserialize], Set]

            pipeline  = Representable::Pipeline::Insert.(pipeline, external_populator,            replace: Representable::CreateObject::Instance)
            pipeline  = Representable::Pipeline::Insert.(pipeline, Representable::Decorate,       delete: true)
            pipeline  = Representable::Pipeline::Insert.(pipeline, Deserialize,                   replace: Representable::Deserialize)
            pipeline  = Representable::Pipeline::Insert.(pipeline, Representable::SetValue,       delete: true) # FIXME: only diff to options without :populator
          end
        else
          parse_pipeline = ->(input, opts) do
            functions = opts[:binding].send(:parse_functions)
            pipeline  = Representable::Pipeline[*functions] # Pipeline[StopOnExcluded, AssignName, ReadFragment, StopOnNotFound, OverwriteOnNil, Collect[#<Representable::Function::CreateObject:0xa6148ec>, #<Representable::Function::Decorate:0xa6148b0>, Deserialize], Set]

            # FIXME: this won't work with property :name, inherit: true (where there is a populator set already).
            pipeline  = Representable::Pipeline::Insert.(pipeline, external_populator, replace: Representable::SetValue) if definition[:populator] # FIXME: only diff to options without :populator
            pipeline
          end
        end

        deserializer_options[:parse_pipeline] ||= parse_pipeline

        if proc = definition[:skip_if]
          proc = Reform::Form::Validate::Skip::AllBlank.new if proc == :all_blank
          deserializer_options.merge!(skip_parse: proc) # TODO: same with skip_parse ==> External
        end

        # per default, everything should be writeable for the deserializer (we're only writing on the form). however, allow turning it off.
        deserializer_options.merge!(writeable: true) unless deserializer_options.key?(:writeable)

        definition
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    end
    extend Property

    require "disposable/twin/changed"
    feature Disposable::Twin::Changed

    require "disposable/twin/sync"
    feature Disposable::Twin::Sync
    feature Disposable::Twin::Sync::SkipGetter

    require "disposable/twin/save"
    feature Disposable::Twin::Save

    require "reform/form/prepopulate"
    include Prepopulate

    def skip!
      Representable::Pipeline::Stop
    end

    require "reform/form/call"
    include Call
  end
end
