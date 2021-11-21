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
      Validate.validate!(nil, values_object: self, form: self, validation_groups: self.class.validation_groups).success?
    end

    # The #errors method will be removed in Reform 3.0 core.
    def errors(*args)
      Result::Errors.new(@result, self)
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

    # Validate the current form instance.
    # NOTE: consider polymorphism here
                                                                  # DISCUSS: ZZdo we like that?
                                                                  # FIXME: do we need the {name} argument here?
    def self.validate!(name, form:, validation_groups:, schema: form.schema, values_object:, deserialized_values: values_object.instance_variable_get(:@deserialized_values))
      # run local validations. this could be nested schemas, too.
      puts "@@@@@ #{values_object.inspect}"
      local_errors_by_group = Reform::Validation::Groups::Validate.(validation_groups, form: form, values_object: values_object, deserialized_values: deserialized_values).compact # TODO: discss compact

puts "local_errors_by_group::::: #{ local_errors_by_group.inspect}"

      nested_errors = validate_nested!(schema: schema, values_object: values_object, deserialized_values: deserialized_values)

puts "nested_errors ........... #{nested_errors.inspect}"

      # Result: unified interface #success?, #messages, etc.
      result = Result.new(
        # custom_errors +  # FIXME
        local_errors_by_group, nested_errors
      )
    end

    private

    # Recursively call validate! on nested forms.
    def self.validate_nested!(schema:, deserialized_values:, values_object:)
      arr = []

      schema.each(twin: true) do |dfn|
        # on collections, this calls validate! on each item form.
        Disposable::Twin::PropertyProcessor.new(dfn, values_object).() do |form, i|
          nested_schema   = dfn[:nested].schema

          nested_result = validate!(dfn[:name], values_object: form, schema: nested_schema, validation_groups: dfn[:nested].validation_groups, form:nil)

          arr << [dfn[:name], i, nested_result]
        end
      end

      arr
    end
  end
end
