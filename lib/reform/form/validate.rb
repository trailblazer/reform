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

  def validate(params, ctx={})
    populated_instance = DeserializedFields.new # DISCUSS: this is (part of) the Twin. "write-to"

    deserialized_values, deserialize_ctx = block_given? ? yield(params) : Reform::Form::Validate.deserialize(params, ctx, twin: self, populated_instance: populated_instance) # FIXME: call deserialize! on every form?

    # FIXME: only one level
    @arbitrary_bullshit = deserialize_ctx # TODO: do we need the entire {Context} instance here?
    @deserialized_values = deserialized_values

    super(deserialized_values: deserialized_values) # run the actual validation using {Contract#validate}.
  end

  # we need a closed structure taht only contains read values. we need values associated with their form (eg. nested, right?)

  # {:twin} where do we write to (currently)
  def self.deserialize(params, ctx, populated_instance:, twin:)
    # puts "@@@@@ deserialize /// #{ctx.inspect}"
    # params = deserialize!(params)
    # deserializer.new(self).from_hash(params)
    ctx = Trailblazer::Context({input: params, populated_instance: populated_instance}, ctx)

    # Run the form's deserializer, which is a simple Trailblazer::Activity.
    # This is where all parsing, defaulting, populating etc happens.
    signal, (ctx, _) = Trailblazer::Developer.wtf?(twin.class.deserializer_activity, [ctx, {}], exec_context: twin)

    raise ctx[:populated_instance].inspect

    fields = []
    twin.schema.each do |dfn|
      fields << dfn[:name]
    end

  # FIXME: this is usually done via SetValue in the pipeline (also important with populators)
  puts "!!!!!!!@@@@@ #{fields.inspect}"
    deserialized_values = fields.collect { |field| ctx.key?(field) ? [field, ctx[field]] : nil }.compact.to_h
    deserialized_values.each do |field, value|
      puts "@@@@@ #{field.inspect} ===> #{value}"
      twin.send("#{field}=", value) # FIXME: hahaha: this actually sets the scalar values on the form
    end # FIXME: this creates two sources for {invoice_date}, sucks

    # arbitrary_bullshit = ctx # TODO: do we need the entire {Context} instance here?

    [deserialized_values, ctx] # These are only fields from params # TODO: see how we can collect those when populators are in place
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
