module Reform
  class Form
    # @Runtime
    # Returned from `Reform.validate`.
    class Validated
      def initialize(deserialized_form, result, nested_validated_forms)
        @deserialized_form = deserialized_form
        @result            = result
        @is_success        = result.success?
        @nested            = nested_validated_forms
        @nested_properties = nested_validated_forms.keys
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
    end # Validated
  end
end
