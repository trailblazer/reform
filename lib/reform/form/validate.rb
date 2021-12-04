# Parse the incoming {#validate} input, deserialize it (using populators, TODO)
# and write parse-pipelined values to their field in the form.
module Reform::Form::Validate
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

  class Validated
    def initialize(form, deserialized_values, arbitrary_bullshit, is_success)
      @form                = form
      @deserialized_values = deserialized_values
      @arbitrary_bullshit  = arbitrary_bullshit
      @is_success = is_success
    end

    def method_missing(name, *args) # DISCUSS: no setter?
      raise unless @form.methods.include?(name) # TODO: only respond to fields!
      # pp @deserialized_values
      @deserialized_values[name]
    end

    def [](name)
      @arbitrary_bullshit[name]
    end

    def errors
      @form.errors # FIXME: don't keep errors there!
    end

    def success?
      @is_success
    end
  end

  def validate(params, ctx={})
    populated_instance = DeserializedFields.new # DISCUSS: this is (part of) the Twin. "write-to"

    deserialized_values, deserialize_ctx = Reform::Form::Validate.deserialize(params, ctx, twin: self, populated_instance: populated_instance) # FIXME: call deserialize! on every form?

    # FIXME: only one level
    @arbitrary_bullshit = deserialize_ctx # TODO: do we need the entire {Context} instance here?
    @deserialized_values = deserialized_values

    result = super(deserialized_values: deserialized_values) # run the actual validation using {Contract#validate}.

    Validated.new(self, deserialized_values, deserialize_ctx, result) # DISCUSS: a validated form has different behavior than a "presented" one
  end

  # we need a closed structure taht only contains read values. we need values associated with their form (eg. nested, right?)

  # {:twin} where do we write to (currently)
  def self.deserialize(params, ctx, populated_instance:, twin:)
    # params = deserialize!(params)
    # deserializer.new(self).from_hash(params)
    ctx = Trailblazer::Context({input: params, populated_instance: populated_instance}, ctx)

    # Run the form's deserializer, which is a simple Trailblazer::Activity.
    # This is where all parsing, defaulting, populating etc happens.
    signal, (ctx, _) = Trailblazer::Developer.wtf?(twin.class.deserializer_activity, [ctx, {}], exec_context: twin)

    deserialized_values = ctx[:populated_instance] # This must be a hash!

    [deserialized_values, ctx] # These are only fields from params
  end

  # This structure only stores fields set by the deserialization.
  class DeserializedFields < Hash
    # def initialize
    #   @fields = {}
    # end

    # def []=(name, value)
    #   @fields[name] = value
    # end
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
