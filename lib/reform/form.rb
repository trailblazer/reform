require "trailblazer/activity/dsl/linear"
require "trailblazer/developer"

# PPP: property parsing pipeline :)
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
      def property(name, options={}, &block)
        parse_block   = options[:parse_block] || ->(*) {} # FIXME: use fucking kwargs everywhere!
        parse_inject  = options[:parse_inject] || [] # per {#property} we can define injection variables for the PPP.

        if (options.keys & %i[skip_if populator]).size == 2
          raise InvalidOptionsCombinationError.new(
            "[Reform] #{self}:property:#{name} Do not use skip_if and populator together, use populator with skip! instead"
          )
        end

        # if composition and inherited we also need this setting
        # to correctly inherit modules
        options[:_inherited] = options[:inherit] if options.key?(:on) && options.key?(:inherit)

        kws = {}

        # When {parse: false} is set, meaning we shall *not* read the property's value from the input fragment,
        # we simply use a slightly slimmer PPP which doesn't have {#key?} and {#read}.
        if options[:parse] == false
          kws[:property_activity] = Deserialize::Property # normally this is {Deserialize::Property::Read}.
        end

        options[:writeable] ||= options.delete(:writable) if options.key?(:writable)

        # for virtual collection we need at least to have the collection equal to [] to
        # avoid issue when the populator
        if (options.keys & %i[collection virtual]).size == 2
          options = { default: [] }.merge(options)
        end

        definition = super(name, options, &block) # letdisposable and declarative gems sort out inheriting of properties, and so on.



        add_property_to_deserializer!(name, deserializer_activity, parse_block: parse_block, inject: parse_inject, **kws)

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
        module Macro
          module_function

          def self.default(*args); return Trailblazer::Activity::Right, *args end # this step doesn't do anything!

          def Default(field_name, static_value)
            {
              task: method(:default),
              after: :read, magnetic_to: :failure, Trailblazer::Activity::Railway.Output(:success) => Trailblazer::Activity::Railway.Track(:success),
              inject: [{ value: ->(ctx, **) {static_value} }],# input: [:key],
              id: :default, field_name: :default  # we don't need {:value} here, do we?
            }
          end
        end

        def self.normalize_field_name((ctx, flow_options), **)
          ctx = ctx.merge(
            field_name: ctx[:field_name] || ctx[:id] # Default to {:id} which is already set by the normalizer.
          )
          return Trailblazer::Activity::Right, [ctx, flow_options]
        end

        # Build our own {step} normalizer so we can add new options like {:provides} and defaulted {:output}.
        def self.normalize_output_options((ctx, flow_options), **)
          output_filter = ctx[:output_filter]
          return Trailblazer::Activity::Right, [ctx, flow_options] if output_filter == false # don't do this if {:output_filter} is {false}.

          # TODO: test {:field_name} overriding
              # TODO: test {:output}, {:provides} overriding
          field_name = ctx[:field_name]

          output_options = { # TODO: example doc
            output:   ->(ctx, value:, **) { {:value => value, :"value.#{field_name}" => value}},
            provides: [:"value.#{field_name}"]
          }

          ctx = ctx.merge(output_options)

          return Trailblazer::Activity::Right, [ctx, flow_options]
        end

        linear = Trailblazer::Activity::DSL::Linear

        railway_step_normalizer_seq = linear::Normalizer.activity_normalizer( Trailblazer::Activity::Railway::DSL.normalizer ) # FIXME: no other way to retrieve the "configuration" of Railway normalizer then to re-compute it.

        seq = Trailblazer::Activity::Path::DSL.prepend_to_path( # this doesn't particularly put the steps after the Path steps.
              railway_step_normalizer_seq,

              {
              "form.property.normalize_field_name"       => Deserialize.method(:normalize_field_name),      # first
              "form.property.normalize_output_options"       => Deserialize.method(:normalize_output_options),      # second
              },

              linear::Insert.method(:Append), "activity.inherit_option" # add our steps after this one.
            )

        normalizers = linear::State::Normalizer.new( # TODO: cache
          step:  linear::Normalizer.activity_normalizer(seq)
        )



        # Base steps for deserializing a particular property field (e.g. {invoice_date}).
        #
        # TODO: currently only with hash input.
        class Property < Trailblazer::Activity::Railway(normalizers: normalizers)

          module StepMethod
            def step(name, output_filter: true, **kws)
              super(name, output_filter: output_filter, **kws) # TODO: defaulting in Normalizer?
            end
          end

          extend StepMethod # we have an extended {#step} method now.

          # The default property that uses {#key?} and {#read} to read from the fragment.
          class Read < Property
            # Default steps
            # Simple check if {key} is present in the incoming document/input.
            def self.key?(ctx, key:, input:, **)
              input.key?(key)
            end

            # Read the property value from the fragment.
            def self.read(ctx, key:, input:, **)
              ctx[:value] = input[key]
            end

            step method(:key?), id: :key?, output_filter: false
            step method(:read), id: :read, field_name: :read # output: ->(ctx, value:, **) { {:value => value, :"value.read" => value}}, provides: [:"value.read"]
          end
        end # Property

        # Override {Railway#call} and always use the top-most {:exec_context},
        # which is the currently validated form.
        module Call
          def call(*args, exec_context:, **kws)
            @activity.(*args, **kws.merge(exec_context: exec_context))
          end
        end


      end

      def add_property_to_deserializer!(field, deserializer_activity, parse_block:, inject:, property_activity: Deserialize::Property::Read)
        property_activity = Class.new(property_activity) # this activity represents one particulr property's pipeline {ppp}.
        property_activity.instance_exec(&parse_block)
        property_activity.extend(Deserialize::Call)

        # Find all variables provided by this PPP.
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
            # input:  [:input],
            # The {:input} filter passes the actual fragment as {:input} and already deserialized
            # field values from earlier steps in {:deserialized_ctx}.
            input:  ->(ctx, input:, **) { {input: input, deserialized_fields: ctx} },
            inject: [*inject, {key: ->(*) { field }}],
            # The {:output} filter adds all values from the property steps to the original ctx,
            # prefixed with the property name, such as {:"invoice_date.value.parsed"}
            output: output_hash, # {:"value.parsed" => :"invoice_date.value.parsed", ..}
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
