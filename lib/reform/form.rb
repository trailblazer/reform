require "trailblazer/activity/dsl/linear"
require "trailblazer/developer"
require "trailblazer/declarative"



# PPP: property parsing pipeline :)
module Reform
  # This class shouldn't implement/expose any runtime behavior. but then, we do define filters here :grimace:
  class Form #< Contract
    # DISCUSS: this is a pure DSL object
    extend Trailblazer::Declarative::Schema::State
    extend Trailblazer::Declarative::Schema::State::Inherited

def self.feature(mod) # FIXME: implement!
  include mod
end

    class InvalidOptionsCombinationError < StandardError; end

    def self.default_nested_class
      Form
    end

    # require "reform/form/validate"
    # include Validate # override Contract#validate with additional behaviour.

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
        kws[:replace] = options[:replace] # FIXME

        # When {parse: false} is set, meaning we shall *not* read the property's value from the input fragment,
        # we simply use a slightly slimmer PPP which doesn't have {#key?} and {#read}.
        if options[:read] == false
          kws[:property_activity] = Deserialize::Property # normally this is {Deserialize::Property::Read}.
          kws[:set] = options.key?(:set) ? options[:set] : true # TODO: handle this with a separate {Property} class.
        end

        options[:writeable] ||= options.delete(:writable) if options.key?(:writable)

        # for virtual collection we need at least to have the collection equal to [] to
        # avoid issue when the populator
        if (options.keys & %i[collection virtual]).size == 2
          options = { default: [] }.merge(options)
        end

        # definition = super(name, options, &block) # letdisposable and declarative gems sort out inheriting of properties, and so on.

        definition = {} # FIXME: how do we store the user options from the form?
        if definition[:nested]
          kws[:additional_deserialize_bla] = definition[:nested].deserializer_activity #->((ctx, flow_options), **circuit_options) {
          #   definition[:nested].deserialize([ctx[:value], flow_options])
          # }
        end


        # DISCUSS: should we update store here?
        state.update!("artifact/deserializer") do |deserializer|
          add_property_to_deserializer!(name, deserializer, parse_block: parse_block, inject: parse_inject, **kws)
        end

        definitions = state.update!("dsl/definitions") do |defs|
          defs.merge(
            name => {name: name} # TOOD: add more
          )
        end

        require "reform/twin"
        state.update!("artifact/twin") do |twin|
          Reform::Twin.add_property_to_twin!(name, twin, definitions, **kws)
        end

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



      module Deserialize
        module Macro
          module_function

          def self.default(*args); return Trailblazer::Activity::Right, *args end # this step doesn't do anything!

          def Default(field_name, static_value)
            {
              task: method(:default),
              after: :read, magnetic_to: :key_not_found, Trailblazer::Activity::Railway.Output(:success) => Trailblazer::Activity::Railway.Track(:success), # DISCUSS: do we need a failure output here?
              inject: [{ value: ->(ctx, **) {static_value} }],# input: [:key],
              id: :default, field_name: :default  # we don't need {:value} here, do we?
            }
          end
        end

        def self.normalize_field_name(ctx, field_name: nil, id:, **)
          ctx[:field_name] = field_name || id # Default to {:id} which is already set by the normalizer.
        end

        # Build our own {step} normalizer so we can add new options like {:provides} and defaulted {:output}.
        def self.normalize_output_options(ctx, output_filter:, field_name:, **)
          return if output_filter == false

          # TODO: test {:field_name} overriding
              # TODO: test {:output}, {:provides} overriding
          ctx[:output]   = ->(ctx, value:, **) { {:value => value, :"value.#{field_name}" => value} }
          ctx[:provides] = [:"value.#{field_name}"]
        end

        linear = Trailblazer::Activity::DSL::Linear

        railway_step_normalizer_pipe = linear::Normalizer.activity_normalizer( Trailblazer::Activity::Railway::DSL.normalizer ) # FIXME: no other way to retrieve the "configuration" of Railway normalizer then to re-compute it.

        pipe = Trailblazer::Activity::TaskWrap::Pipeline.prepend(
          railway_step_normalizer_pipe,
          "path.outputs",
          {
          "form.property.normalize_field_name"       => linear::Normalizer.Task(Deserialize.method(:normalize_field_name)),      # first
          "form.property.normalize_output_options"   => linear::Normalizer.Task(Deserialize.method(:normalize_output_options)),  # second
          }
        )

        normalizers = linear::State::Normalizer.new(
          step:  pipe
        )



        # Base steps for deserializing a particular property field (e.g. {invoice_date}).
        #
        # Current standard wiring
        #
        #            |-----------> [default] v ----------=> End.key_not_found
        # Start -> key? -> read -> [your parsing] -> set -> End.success
        #                                |----------_set-=> End.failure
        #
        # TODO: currently only with hash input.
        # TODO: {default} will go back to Track(:success) and hence do user processing if set. Do we want that?
        class Property < Trailblazer::Activity::Railway(normalizers: normalizers)
          @state.update_sequence do |sequence:, **| # FIXME: make it easier to add termini!
            sequence = Trailblazer::Activity::Path::DSL.append_end(sequence, task: Trailblazer::Activity::End.new(semantic: :key_not_found), magnetic_to: :key_not_found, id: "End.key_not_found")

            recompile_activity!(sequence)

            sequence
          end


          module StepMethod
            # Per default, step adds an {:output} filter that only returns {:value} and {value.field_name}.
            # Can be turned off with {output_filter: false}. That means a step like {set} will return the original ctx with all fields.
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

            step method(:key?), id: :key?, output_filter: false, Output(:failure) => Track(:key_not_found) # TODO: use a path, make {End.failure} magnetic to "key-not-found".
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

      def set(ctx, populated_instance:, value:, key:, **)
        # TODO: handle populators

        # standard populator:
        # populated_instance[key] = value
        ctx[:populated_instance] = populated_instance.merge(key => value) # TODO: this {populated_instance} is supposed to be the form twin. in only use the immutable version to test if we use a proper clean output filter.

        true
      end
      def add_property_to_deserializer!(field, deserializer_activity, parse_block:, inject:, property_activity: Deserialize::Property::Read, set: true, additional_deserialize_bla: false, replace: nil)
        property_activity = Class.new(property_activity) # this activity represents one particular property's pipeline {ppp}.
        property_activity.instance_exec(&parse_block)
        property_activity.extend(Deserialize::Call)

        # DISCUSS: it would be better to have :set in the {property_activity} before we execute {&parse_block}
        #          because it would allow tweaking it using your {:parse_block}.

        if additional_deserialize_bla
          property_activity.step Trailblazer::Activity::Railway.Subprocess(additional_deserialize_bla), id: :deserialize_nested,
            input: ->(ctx, twin:, value:, **) { # input going into the nested "form"
              {
                populated_instance: Validate::DeserializedFields.new,
                twin: twin.send(:band), # FIXME
                input: value,
              }
            },
            output: ->(ctx, outer_ctx, populated_instance:, twin:, **) {
              # raise outer_context.inspect
              {
                value: Validate::Deserialized.new(twin, populated_instance, ctx), # this is used in {set}.
                # populated_instance: outer_ctx[:populated_instance].merge(band: populated_instance,), # DISCUSS: should we do that later, at validation time?


                # Here we would have to return the mutated twin

              }
            }, output_filter: false, output_with_outer_ctx: true

        end

        if set # FIXME: hm, well, i hate {if}s, don't i?
          property_activity.step(method(:set), id: :set, output_filter: false) # FIXME: needs to be at the very end
          # FIXME: do we want this?
          class << self
            alias _set set
          end
          # TODO: use #fail.
          property_activity.step method(:_set), id: :"set.fail", output_filter: false, magnetic_to: :failure, Trailblazer::Activity::Railway.Output(:success) => Trailblazer::Activity::Railway.Track(:failure)  # FIXME: needs to be at the very end
        end


        # Find all variables provided by this PPP.
        # E.g. {[:"value.read", :"value.parse_user_date", :"value.coerce"]}
        # We need to rename those in the activities {:output}, see below.
        # TODO: in future TRB versions, {:output} could know what variables it returns?
        provided_variables = property_activity.to_h[:nodes].collect { |n| n.data[:provides] }.flatten(1).compact

        # E.g. {:"value.read"=>:"invoice_date.value.read", ..., :value=>:invoice_date}
        output_hash = (provided_variables.collect { |inner_name| [inner_name, :"#{field}.#{inner_name}"] } + [[:value, field]]).to_h

        fixme_options = {}
        fixme_options = {
            replace: replace # FIXME, untested shit
          } if replace
        # DISCUSS: we're mutating here.
        deserializer_activity.instance_exec do
          step Subprocess(property_activity),
            id:     field,
            # input:  [:input],
            # The {:input} filter passes the actual fragment as {:input} and already deserialized
            # field values from earlier steps in {:deserialized_ctx}.
            input:  ->(ctx, input:, twin:, **) { {input: input, deserialized_fields: ctx, populated_instance: ctx[:populated_instance], twin: twin} },
            inject: [*inject, {key: ->(*) { field }}],
            # The {:output} filter adds all values from the property steps to the original ctx,
            # prefixed with the property name, such as {:"invoice_date.value.parsed"}
            output: output_hash. # {:"value.parsed" => :"invoice_date.value.parsed", ..}
              merge(populated_instance: :populated_instance),
            Output(:failure) => Track(:success), # a failing {read} shouldn't skip the remaining properties # FIXME: test me!
            Output(:key_not_found) => Track(:success), # experimental output for {:key?} failure track
            **fixme_options
        end

        deserializer_activity
      end
    end
    extend Property



    # require "disposable/twin/changed"
    # feature Disposable::Twin::Changed

    # require "disposable/twin/sync"
    # feature Disposable::Twin::Sync
    # feature Disposable::Twin::Sync::SkipGetter

    # require "disposable/twin/save"
    # feature Disposable::Twin::Save

    def skip!
      Representable::Pipeline::Stop
    end

    require "reform/form/call"
    include Call

# TODO: this should be at the top of class body at some point :)
    def self.initial_deserializer_activity
      Class.new(Trailblazer::Activity::Railway) do
        extend(Property::Deserialize::Call)
      end
    end

    initialize_state!(
      "artifact/hydrate" =>       [Class.new(Trailblazer::Activity::Railway), {copy: Trailblazer::Declarative::State.method(:subclass)}],
      "artifact/deserializer" =>  [initial_deserializer_activity, {copy: Trailblazer::Declarative::State.method(:subclass)}],
      "artifact/twin" => [Hash.new, {}], # copy # FIXME: we need real definitions here, I guess.
      "dsl/definitions" => [Hash.new, {}] # copy # FIXME: we need real definitions here, I guess.
    )

    require "reform/form/dsl/validation"
    require "reform/validation/groups"
    extend DSL::Validation # Form.validation do .. end

  end
end
    require "reform/form/validate"

require "reform/form/sync"
