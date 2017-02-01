class Reform::Contract < Disposable::Twin # i hate that so much. will we get namespace, ever?
  module Validate
    def validate
      validate!(nil).success?
    end

    def errors(*args)
      @result.errors(*args) if args.size > 0 # Reform 2.4/3.0 API. really return errors.

      Result::Errors.new(@result)
    end

    def validate!(name, pointers=[])
      # run local validations. this could be nested schemas, too.
      local_errors_by_group = Reform::Validation::Groups::Validate.(self.class.validation_groups, self).compact # TODO: discss compact

      # blindly add injected pointers. will be readable via #errors.
      # also, add pointers from local errors here.
      pointers_for_nested = pointers + local_errors_by_group.collect { |errs| Result::Pointer.new(errs, []) }.compact

      nested_errors = validate_nested!(pointers_for_nested)

      @result = Result.new(local_errors_by_group + pointers, nested_errors)
    end

  private

    # Recursively call validate! on nested forms.
    # A pointer keeps an entire result object (e.g. Dry result) and
    # the relevant path to its fragment, e.g. <Dry::result{.....} path=songs,0>
    def validate_nested!(pointers)
      arr = []

      schema.each(twin: true) do |dfn|
        # on collections, this calls validate! on each item form.
        Disposable::Twin::PropertyProcessor.new(dfn, self).() { |form, i|
          nested_pointers = pointers.collect { |pointer| pointer.advance(dfn[:name].to_sym, i) }.compact # pointer contains fragment for us, so go deeper

          arr << form.validate!(dfn[:name], nested_pointers)
        }
      end

      arr
    end
  end
end


# errors.messages

# http://api.rubyonrails.org/classes/ActiveModel/Errors.html
# person.errors.full_messages
# # => ["Name is too short (minimum is 5 characters)", "Name can't be blank", "Email can't be blank"]
# person.errors.messages
# # => {:name=>["is invalid", "must be implemented"]}
