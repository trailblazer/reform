class Reform::Contract < Disposable::Twin
  module Validate
    # def initialize(*)
    #   # this will be removed in Reform 3.0. we need this for the presenting form, form builders
    #   # call the Form#errors method before validation.
    #   super
    #   @result = Result.new([])
    # end

    def validate(deserialized_values:) # FIXME: {self} values is for AMV
      # DISCUSS: we don't need {deserialized_values} here as it's stored in form:@deserialized_values
      result = Validate.validate!(nil, values_object: self, form: self, validation_groups: self.class.validation_groups)

      @errors = result.errors
      @result = result
      result.success?
    end

    # The #errors method will be removed in Reform 3.0 core.
    def errors(*args)
      #Result::Errors.new(@result, self)
      @errors
    end

    #:private:
    # only used in tests so far. this will be the new API in #call, where you will get @result.
    def to_result
      @result
    end

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
        #@form.errors # FIXME: don't keep errors there!
        @result.errors
      end

      def success?
        @is_success
      end

      def method_missing(name, *args)
        return @nested[name.to_s] if @nested_properties.include?(name.to_s) # DISCUSS: return nested {Validated} for instance for {form.band}.

        @deserialized_form.send(name, *args)
      end
    end

    # Validate the current form instance.
    # NOTE: consider polymorphism here
                                                                  # DISCUSS: ZZdo we like that?
                                                                  # FIXME: do we need the {name} argument here?
    def self.run_validations(name, twin:, validation_groups:, schema: twin.schema, deserialized_form:)
      # run local validations. this could be nested schemas, too.
      # puts "@@@@@ #{values_object.inspect}"
      local_errors_by_group = Reform::Validation::Groups::Validate.(validation_groups, exec_context: twin, deserialized_form: deserialized_form).compact # TODO: discss compact

puts "local_errors_by_group::::: #{ local_errors_by_group.inspect}"

      nested_validated_forms = validate_nested!(schema: schema, deserialized_form: deserialized_form)

# puts "nested_validated_forms ........... #{nested_validated_forms.inspect}"

      # Result: unified interface #success?, #messages, etc.
      result = Result.new(
        # custom_errors +  # FIXME
        local_errors_by_group#, nested_errors
      )
puts "@@@@@ ++++ #{result.inspect}"

      Validated.new(deserialized_form, result, nested_validated_forms)
    end

    def self.iterate_nested(schema:, deserialized_form:, only_twin: true) # TODO: allow {collect}
      collected = []

      schema.each(twin: only_twin) do |dfn|
        # nested_schema = dfn[:nested].schema
        if is_collection = dfn[:collection] # FIXME: not sure this works. yet.
raise "implement collections!!!"
        else
          collected << [dfn[:name], yield(deserialized_form.send(dfn[:name]), i: 0, definition: dfn)]
        end
      end

      collected
    end

    # Recursively call run_validations on nested forms.
    def self.validate_nested!(schema:, deserialized_form:)
      nested_forms = iterate_nested(schema: schema, deserialized_form: deserialized_form) do |nested_deserialized_form, definition:, i:, **|
        # this block returns a nested {Validated} form:
        run_validations(nil,
          deserialized_form:  nested_deserialized_form,
          twin:               nested_deserialized_form.instance_variable_get(:@form), # FIXME: should pass {:twin} implicitely around through {DF}?
          validation_groups:  nested_deserialized_form.instance_variable_get(:@form).class.validation_groups,
        )
      end

      nested_forms.to_h
    end
  end
end
