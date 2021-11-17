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

  def validate(params)
    values = block_given? ? yield(params) : deserialize(params)

    super(values: values) # run the actual validation on self.
  end

  def deserialize(params)
    # params = deserialize!(params)
    # deserializer.new(self).from_hash(params)
    ctx = Trailblazer::Context({input: params}, {data: {}})

    signal, (ctx, _) = Trailblazer::Developer.wtf?(self.class.deserializer_activity, [ctx, {}], exec_context: self)

    fields = @fields.keys # FIXME: use schema!

  # FIXME: this is usually done via SetValue in the pipeline (also important with populators)
    values = fields.collect { |field| ctx.key?(field) ? [field, ctx[field]] : nil }.compact.to_h
    values.each do |field, value|
      self.send("#{field}=", value) # FIXME: hahaha: this actually sets the scalar values on the form
    end # FIXME: this creates two sources for {invoice_date}, sucks

    @arbitrary_bullshit = ctx # TODO: do we need the entire {Context} instance here?

    values
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
