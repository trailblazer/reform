require "trailblazer/activity/dsl/linear"
require "trailblazer/developer"

module Reform
  class Form < Contract
    class InvalidOptionsCombinationError < StandardError; end

    def self.default_nested_class
      Form
    end

    require "reform/form/validate"
    include Validate # override Contract#validate with additional behaviour.

    require "reform/form/populator"

    # FIXME: move
    def [](name)
      @arbitrary_bullshit ||= {} # FIXME
      @arbitrary_bullshit[name]
    end

    # DISCUSS: should this be {form/property.rb}?
    module Property
      # Add macro logic, e.g. for :populator.
      def property(name, parse_block: ->(*) {}, **options, &block)
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



        add_property_to_deserializer!(name, deserializer_activity, parse_block: parse_block)

=begin
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
=end

        definition
      end

      def deserializer_activity
        @deserializer_activity ||= Class.new(Trailblazer::Activity::Railway) do # FIXME: how to do that without ||=?
          extend(Deserialize::Call)
        end
      end

      module Deserialize
        # Base steps for deserializing a particular property field (e.g. {invoice_date}).
        #
        # TODO: currently only with hash input.
        class Property < Trailblazer::Activity::Railway
          module StepMethod
            def step(name, field_name: name, **kws)
              # TODO: test {:field_name} overriding
              # TODO: test {:output}, {:provides} overriding

              output_options = { # TODO: example doc
                output:   ->(ctx, value:, **) { {:value => value, :"value.#{field_name}" => value}},
                provides: [:"value.#{field_name}"]
              }

              super(name, **output_options, **kws)
            end
          end

          extend StepMethod # we have an extended {#step} method now.

          # Default steps
          # Read the property value from the fragment.
          def self.read(ctx, key:, input:, **)
            ctx[:value] = input[key]
          end

          step method(:read), id: :read, field_name: :read # output: ->(ctx, value:, **) { {:value => value, :"value.read" => value}}, provides: [:"value.read"] # TODO: what if not existing etc?

        end # Property

        # Override {Railway#call} and always use the top-most {:exec_context},
        # which is the currently validated form.
        module Call
          def call(*args, exec_context:, **kws)
            @activity.(*args, **kws.merge(exec_context: exec_context))
          end
        end


      end

      def add_property_to_deserializer!(field, deserializer_activity, parse_block:)
        property_activity = Class.new(Deserialize::Property) # this activity represents one particulr property's pipeline {ppp}.
        property_activity.instance_exec(&parse_block)
        property_activity.extend(Deserialize::Call)

        # Find all variables provided by this property pipeline.
        # E.g. {[:"value.read", :"value.parse_user_date", :"value.coerce"]}
        # We need to rename those in the activities {:output}, see below.
        # TODO: in future TRB versions, {:output} could know what variables it returns?
        provided_variables = property_activity.to_h[:nodes].collect { |n| n.data[:provides] }.flatten(1).compact

        # E.g. {:"value.read"=>:"invoice_date.value.read", ..., :value=>:invoice_date}
        output_hash = (provided_variables.collect { |inner_name| [inner_name, :"#{field}.#{inner_name}"] } + [[:value, field]]).to_h

        # DISCUSS: we're mutating here.
        deserializer_activity.instance_exec do
          step Subprocess(property_activity),
            id:     field,
            input:  [:input],
            inject: [{key: ->(*) { field }}],
            # output: {:"value.parsed" => :"#{field}.parsed", :"value.read" => :"#{field}.read", :"value.coerced" => :"#{field}.coerced", :value => field},
            output: output_hash,
            Output(:failure) => Track(:success) # a failing {read} shouldn't skip the remaining properties # FIXME: test me!
        end
      end
    end
    extend Property

    # require "disposable/twin/changed"
    # feature Disposable::Twin::Changed

    require "disposable/twin/sync"
    feature Disposable::Twin::Sync
    feature Disposable::Twin::Sync::SkipGetter

    require "disposable/twin/save"
    feature Disposable::Twin::Save

    def skip!
      Representable::Pipeline::Stop
    end

    require "reform/form/call"
    include Call
  end
end
