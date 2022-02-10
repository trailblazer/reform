# Parse the incoming {#validate} input, deserialize it (using populators, TODO)
# and write parse-pipelined values to their field in the form.
class Reform::Form
  # run_validations(name, twin:, validation_groups:, schema: twin.schema, deserialized_form:)
  def self.validate(twin, params, ctx)
    populated_instance = DeserializedFields.new # DISCUSS: this is (part of) the Twin. "write-to"

    deserialized_form = Validate.deserialize(params, ctx, twin: twin, populated_instance: populated_instance)

    # pp deserialized_form
    puts deserialized_form.to_input_hash.inspect

    return deserialized_form,
      Reform::Contract::Validate.run_validations(nil, deserialized_form: deserialized_form, twin: twin, validation_groups: twin.class.validation_groups)
  end

  module Validate
    module Skip
      class AllBlank # FIXME: what the fuck is this?
        include Uber::Callable

        def call(input:, binding:, **)
          # TODO: Schema should provide property names as plain list.
          # ensure param keys are strings.
          params = input.each_with_object({}) { |(k, v), hash|
            hash[k.to_s] = v
          }

          # return false if any property inputs are populated.
          binding[:nested].definitions.each do |definition|
            value = params[definition.name.to_s]
            return false if (!value.nil? && value != '')
          end

          true # skip this property
        end
      end
    end

    class Deserialized
      def initialize(form, populated_instance, arbitrary_bullshit)
        @form                = form
        @populated_instance = populated_instance # populated_instance
        @arbitrary_bullshit  = arbitrary_bullshit # ctx of the PPP
      end

      def method_missing(name, *args) # DISCUSS: no setter?
        raise name.inspect unless @form.methods.include?(name) # TODO: only respond to fields!

        if @populated_instance.key?(name)
          # pp @populated_instance
          @populated_instance[name]
        else # helper method such as {:txn_types_for_radio_buttons} # FIXME: test this case
          @form.send(name, *args)
        end
      end

      def [](name)
        @arbitrary_bullshit[name]
      end

      def []=(name, value) # DISCUSS: is this our official setter when you don't want to parse-populate?
        @populated_instance[name] = value
      end


      def to_input_hash
        @populated_instance # FIXME: this still contains nested forms!
      end
    end


    # we need a closed structure taht only contains read values. we need values associated with their form (eg. nested, right?)

    # {:twin} where do we write to (currently)
    def self.deserialize(params, ctx, populated_instance: DeserializedFields.new, twin:)
      # params = deserialize!(params)
      # deserializer.new(self).from_hash(params)
      ctx = Trailblazer::Context({input: params, populated_instance: populated_instance, twin: twin}, ctx)

      # Run the form's deserializer, which is a simple Trailblazer::Activity.
      # This is where all parsing, defaulting, populating etc happens.
      # puts Trailblazer::Developer.render(twin.class.deserializer_activity)
      # FIXME: retrieving the deserializer here sucks.
      signal, (ctx, _) = Trailblazer::Developer.wtf?(twin.class.state.get("artifact/deserializer"), [ctx, {}], exec_context: twin) # exec_context because filter methods etc are defined on the FORM which is the {twin} currently

  # FIXME: the following code should be done via {:output} just like for nested forms

  # At this p(o)int, we have a hash of deserialized values (potentially missing keys etc as they're dependent on user input)
  # We also have the "value object" (twin) populated in {populated_instance}
  # pp deserialized_values

      Deserialized.new(twin, ctx[:populated_instance], ctx)
    end

    # [{values}, {all fields}, twin, {band: [{v}, {f}, twin]}]

    # This structure only stores fields set by the deserialization.
    class DeserializedFields < Hash
    end

    private

  #  TODO: eg. rails form accessor shit
    # # Meant to return params processable by the representer. This is the hook for munching date fields, etc.
    # def deserialize!(params)
    #   # NOTE: it is completely up to the form user how they want to deserialize (e.g. using an external JSON-API representer).
    #   # use the deserializer as an external instance to operate on the Twin API,
    #   # e.g. adding new items in collections using #<< etc.
    #   # DISCUSS: using self here will call the form's setters like title= which might be overridden.
    #   params
    # end
  end
end
