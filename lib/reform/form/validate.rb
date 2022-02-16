# Parse the incoming {#validate} input, deserialize it (using populators, TODO)
# and write parse-pipelined values to their field in the form.
class Reform::Form
  # run_validations(name, twin:, validation_groups:, schema: twin.schema, deserialized_form:)
  def self.validate(form_class, params, ctx, paired_model: nil)
    deserialized_form = Reform::Deserialize.deserialize(form_class, params, paired_model, ctx)

    # pp deserialized_form
    # puts deserialized_form.to_input_hash.inspect

    return deserialized_form,
      Reform::Validate.run_validations(nil,
        form_class:         form_class,
        deserialized_form:  deserialized_form
      )
  end

  module Validate
    module Skip
      class AllBlank # FIXME: what the fuck is this?
        # include Uber::Callable

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
  end
end
