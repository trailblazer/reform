class Reform::Contract < Disposable::Twin
  module Validate
    def initialize(*)
      # this will be removed in Reform 3.0. we need this for the presenting form, form builders
      # call the Form#errors method before validation.
      super
      @result = Result.new([])
    end

    def validate
      validate!(nil).success?
    end

    # The #errors method will be removed in Reform 2.4/3.0 core.
    def errors(*args)
      Result::Errors.new(@result, self)
    end

    #:private:
    # only used in tests so far. this will be the new API in #call, where you will get @result.
    def to_result
      @result
    end

    def custom_errors
      @result.to_results.select { |result| result.is_a? Reform::Contract::CustomError }
    end

    def validate!(name, pointers = [])
      # run local validations. this could be nested schemas, too.
      local_errors_by_group = Reform::Validation::Groups::Validate.(self.class.validation_groups, self).compact # TODO: discss compact

      # blindly add injected pointers. will be readable via #errors.
      # also, add pointers from local errors here.
      pointers_for_nested = pointers + local_errors_by_group.collect { |errs| Result::Pointer.new(errs, []) }.compact

      nested_errors = validate_nested!(pointers_for_nested)

      # Result: unified interface #success?, #messages, etc.
      @result = Result.new(custom_errors + local_errors_by_group + pointers, nested_errors)
    end

    private

    # Recursively call validate! on nested forms.
    # A pointer keeps an entire result object (e.g. Dry result) and
    # the relevant path to its fragment, e.g. <Dry::result{.....} path=songs,0>
    def validate_nested!(pointers)
      arr = []

      schema.each(twin: true) do |dfn|
        # on collections, this calls validate! on each item form.
        Disposable::Twin::PropertyProcessor.new(dfn, self).() do |form, i|
          nested_pointers = pointers.collect { |pointer| pointer.advance(dfn[:name].to_sym, i) }.compact # pointer contains fragment for us, so go deeper

          arr << form.validate!(dfn[:name], nested_pointers)
        end
      end

      arr
    end
  end
end
