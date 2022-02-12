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
