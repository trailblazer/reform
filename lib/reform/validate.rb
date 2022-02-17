module Reform
  module Validate

# FIXME: what the hell is this?
    def custom_errors
      @result.to_results.select { |result| result.is_a? Reform::Contract::CustomError }
    end

    class Validated
      def initialize(deserialized_form, result, nested_validated_forms)
        @deserialized_form = deserialized_form
        @result            = result
        @is_success        = result.success?
        @nested            = nested_validated_forms
        @nested_properties = nested_validated_forms.keys

# raise result.inspect
      end

      def errors
        @result.errors
      end

      def success?
        @is_success
      end

      def [](name)
        @deserialized_form[name]
      end

      def method_missing(name, *args)
        return @nested[name] if @nested_properties.include?(name) # DISCUSS: return nested {Validated} for instance for {form.band}.

        @deserialized_form.send(name, *args)
      end
    end

    # DISCUSS: we could be using an activity here, too, instead of using recursion?
    # Validate the current form instance.
    # NOTE: consider polymorphism here
                                                                  # DISCUSS: ZZdo we like that?
                                                                  # FIXME: do we need the {name} argument here?
    def self.run_validations(name, form_class:, validation_groups: form_class.state.get("artifact/validation_groups"), schema: form_class.state.get("dsl/definitions"), deserialized_form:)
      # run local validations. this could be nested schemas, too.
      # puts "@@@@@ #{values_object.inspect}"
      local_errors_by_group = Reform::Validation::Groups::Validate.(validation_groups, exec_context: "twin", deserialized_form: deserialized_form).compact # TODO: discss compact FIXME: :exec_context

puts "local_errors_by_group::::: #{ local_errors_by_group.inspect}"

      nested_validated_forms = validate_nested!(schema: schema, deserialized_form: deserialized_form)

# puts "nested_validated_forms ........... #{nested_validated_forms.inspect}"

      # Result: unified interface #success?, #messages, etc.
      result = Reform::Result.new(
        # custom_errors +  # FIXME
        local_errors_by_group#, nested_errors
      )
puts "@@@@@ ++++ #{result.inspect}"

      Validated.new(deserialized_form, result, nested_validated_forms)
    end

    def self.iterate_nested(schema:, deserialized_form:) # TODO: allow {collect}
      schema.collect do |name, dfn|
        next unless dfn[:nested]

        # nested_schema = dfn[:nested].schema
        if is_collection = dfn[:collection] # FIXME: not sure this works. yet.
raise "implement collections!!!"
        else
          [dfn[:name], yield(deserialized_form.send(dfn[:name]), i: 0, definition: dfn)]
        end
      end.compact
    end

    # Recursively call run_validations on nested forms.
    def self.validate_nested!(schema:, deserialized_form:)
      nested_forms = iterate_nested(schema: schema, deserialized_form: deserialized_form) do |nested_deserialized_form, definition:, i:, **|
        # this block returns a nested {Validated} form:
        run_validations(nil,
          deserialized_form:  nested_deserialized_form,
          form_class:         definition[:nested]
        )
      end

      nested_forms.to_h
    end
  end
end
