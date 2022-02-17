module Reform
  # Default: create an empty Hydrated form from the schema.
  module Hydrate
    module DSL
      def self.add_property_to_hydrate!(hydrate_activity, definition:, property_activity: Hydrate::Property::Read)
        property_activity = Deserialize::DSL.property_activity_for(property_activity, &-> {})
        field             = definition[:name]

        # TODO: nesting
        if definition[:nested]
          add_nested_hydrate_to_property!(property_activity, definition, before: :set) # DISCUSS: still not sure I like the mutation.
        end

        hydrate_activity.send :step, Trailblazer::Activity::Railway.Subprocess(property_activity),
          id: field,

          # Trailblazer::Activity::Railway::Inject() => {value: ->(ctx, ** ) { raise ctx.inspect }}, # DISCUSS: every field is blank string? this must be removed if we want to read value in {Read}.
          # Trailblazer::Activity::Railway::Inject() => {input: ->(ctx, **) { raise ctx.inspect }}, # DISCUSS: every field is blank string? this must be removed if we want to read value in {Read}.

          Trailblazer::Activity::Railway::Inject() => {key:   ->(*) { field }},# FIXME: totally  redundant with Deserialize.
          Trailblazer::Activity::Railway.In() => [:populated_instance, :input],
          Trailblazer::Activity::Railway.Out() => [:populated_instance]

        hydrate_activity
      end

    # |   |-- band In:(:populated_instance, :input)
    # |   |   |-- Start.default
    # |   |   |-- #<Method: #<Class:>.read>     # sets {:value}
    # |   |   |-- #<Method: #<Class:>.populate>       # TODO: this is where {skip!} happens!
    # |   |   |-- hydrate_nested.band
    # |   |   |   |-- Start.default
    # |   |   |   |-- name
    # |   |   |   |   |-- Start.default
    # |   |   |   |   |-- #<Method: #<Class:>.read>
    # |   |   |   |   |-- #<Method: #<Class:>.populate>
    # |   |   |   |   |-- set
    # |   |   |   |   `-- End.success
    # |   |   |   `-- End.success
    # |   |   |-- set # writes {:value} to outer {:populated_instance}
    # |   |   `-- End.success Out:(:populated_instance)
    # |   `-- End.success
    # `-- End.success



      def self.add_nested_hydrate_to_property!(property_activity, definition, **step_options)
        nested_form         = definition[:nested]
        nested_deserializer = nested_form.state.get("artifact/hydrate")
        nested_schema       = nested_form.state.get("dsl/definitions")
        field = definition[:name]

        property_activity.send :step, Trailblazer::Activity::Railway.Subprocess(nested_deserializer), id: :"hydrate_nested.#{field}",
          # this logic is executed when {band.read} was successful, right?
          input: ->(ctx, value:, model_from_populator:, **) { # input going into the nested "form"
            {
              populated_instance: Deserialize::DeserializedFields[:model_from_populator => model_from_populator], # DISCUSS: where do we want to keep the reference to the "populated model"?
              # twin: twin.send(:band), # FIXME
              exec_context_instance: nested_form.new, # FIXME: when do we add model, etc? populator logic!
              input: value,
            }
          }, # FIXME: totally  redundant with Deserialize.
          output: ->(ctx, populated_instance:, **) {
            # raise outer_context.inspect
            {
              value: Form::Deserialized.new(nested_schema, nil, populated_instance, ctx.to_h.merge(model_from_populator: populated_instance[:model_from_populator])), # this is used in {set}.
            }
          },
          **step_options

        property_activity
      end
    end # DSL

    module Property

      class Read < Trailblazer::Activity::Railway
        # DISCUSS: we're run before nested_hydrate, so we don't have {:input}
        def self.read(ctx, input:, key:, **)
          ctx[:value] = input.send(key)
        end

        # @param value: the read property's value. when hydrating, this is a {model}, i guess?
        # @param input: the nested fragment that includes the property's value
        def self.populate(ctx, value:, input:, key:, **)

          puts "@@@@@ #{key.inspect}       >>> #{input.inspect}"
          puts "@@@@@x #{value.inspect}"

          ctx[:model_from_populator] = value # here, we could find, run logic, skip etc.

          true # FIXME: how do we know population worked?
        end

        pass method(:read) # read from the "params" model
        step method(:populate)
        step Deserialize.method(:set), id: :set # writes {:populated_instance[key] = value}
      end
    end

    # @Runtime
    # @return Deserialized A `Deserialized` form instance
    #  FIXME: everything super redundant, see Deserialize
    def self.hydrate(form_class, params, ctx)
      # this will create a property with the "first" "nested" form being {form_class}: Definition(name: :_endpoint, nested: form_class)
      # FIXME: do this at compile-time
      endpoint_form = DSL.add_nested_hydrate_to_property!(Class.new(Trailblazer::Activity::Railway), Form::Property::Definition.new(:_endpoint, form_class)) # DISCUSS: {:_endpoint} could be {:song}.

      # we're now running the endpoint form, its only task is to "run the populator" to create the real top-level form (plus twins, model, whatever...)
      # as the endpoint form is not a real form but just the "nested deserializer" part of a property, we don't need several fields here
      OpenStruct.new(_endpoint: params)

      ctx = Trailblazer::Context({twin: "nilll", value: params, model_from_populator: params}, ctx)

      # Run the form's deserializer, which is a simple Trailblazer::Activity.
      # This is where all parsing, defaulting, populating etc happens.
      # puts Trailblazer::Developer.render(twin.class.deserializer_activity)

      signal, (ctx, _) = Trailblazer::Developer.wtf?(endpoint_form, [ctx, {}], exec_context: "nil") # exec_context because filter methods etc are defined on the FORM which is the {twin} currently

  # FIXME: the following code should be done via {:output} just like for nested forms

  # At this p(o)int, we have a hash of deserialized values (potentially missing keys etc as they're dependent on user input)
  # We also have the "value object" (twin) populated in {populated_instance}
  # pp deserialized_values

      ctx[:value] # returns a {Deserialized} instance
    end
  end
end
