module Reform
  module Deserialize
    # @Runtime
    def self.set(ctx, populated_instance:, value:, key:, **)
      # TODO: handle populators

      # standard populator:
      # populated_instance[key] = value
      ctx[:populated_instance] = populated_instance.merge(key => value) # TODO: this {populated_instance} is supposed to be the form twin. in only use the immutable version to test if we use a proper clean output filter.

      true
    end
    # FIXME: do we want this?
    class << self # self.singleton class
      alias _set set
    end

    module DSL

      # |-- band              (i am a property deserializer, PPP, Property::Read)
      # |   |-- Start.default
      # |   |-- key?
      # |   |-- read
      # |   |-- deserialize_nested
      # |   |   |-- Start.default
      # |   |   |-- name
      # |   |   |   |-- Start.default
      # |   |   |   |-- key?
      # |   |   |   |-- read
      # |   |   |   |-- set
      # |   |   |   `-- End.success
      # |   |   `-- End.success
      # |   |-- set
      # |   `-- End.success
      # `-- End.success

      def self.add_property_to_deserializer!(field, deserializer_activity, parse_block:, inject:, property_activity: Deserialize::Property::Read, set: true, definition:, replace: nil)
        property_activity = Class.new(property_activity) # this activity represents one particular property's pipeline {ppp}.
        property_activity.instance_exec(&parse_block)
        property_activity.extend(Reform::Form::Call)

        # DISCUSS: it would be better to have :set in the {property_activity} before we execute {&parse_block}
        #          because it would allow tweaking it using your {:parse_block}.

        if definition[:nested] # FIXME: here, we have to add populator steps/filters.
          add_nested_deserializer_to_property!(property_activity, definition)
        end

        if set # FIXME: hm, well, i hate {if}s, don't i?
          property_activity.step(Deserialize.method(:set), id: :set, output_filter: false) # FIXME: needs to be at the very end

          # TODO: use #fail.
          property_activity.step Deserialize.method(:_set), id: :"set.fail", output_filter: false, magnetic_to: :failure, Trailblazer::Activity::Railway.Output(:success) => Trailblazer::Activity::Railway.Track(:failure)  # FIXME: needs to be at the very end
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

      def self.add_nested_deserializer_to_property!(property_activity, definition)
        nested_form = definition[:nested]
        nested_deserializer = nested_form.state.get("artifact/deserializer")
        nested_schema       = nested_form.state.get("dsl/definitions")

        property_activity.send :step, Trailblazer::Activity::Railway.Subprocess(nested_deserializer), id: :deserialize_nested,
          # this logic is executed when {band.read} was successful, right?
          input: ->(ctx, twin:, value:, **) { # input going into the nested "form"
            {
              populated_instance: Reform::Form::Validate::DeserializedFields.new,
              # twin: twin.send(:band), # FIXME
              twin: nested_form.new, # FIXME: when do we add model, etc? populator logic!
              input: value,
            }
          },
          output: ->(ctx, outer_ctx, populated_instance:, twin:, **) {
            # raise outer_context.inspect
            {
              value: Reform::Form::Validate::Deserialized.new(nested_schema, twin, populated_instance, ctx), # this is used in {set}.
              # populated_instance: outer_ctx[:populated_instance].merge(band: populated_instance,), # DISCUSS: should we do that later, at validation time?


              # Here we would have to return the mutated twin

            }
          }, output_filter: false, output_with_outer_ctx: true

        property_activity
      end
    # end


#FIXME: this is not Form-specific
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
        "form.property.normalize_field_name"       => linear::Normalizer.Task(DSL.method(:normalize_field_name)),      # first
        "form.property.normalize_output_options"   => linear::Normalizer.Task(DSL.method(:normalize_output_options)),  # second
        }
      )

      Normalizers = linear::State::Normalizer.new(
        step:  pipe
      )
    end

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
    class Property < Trailblazer::Activity::Railway(normalizers: DSL::Normalizers)
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


  end # Deserialize
end
