class Reform::Contract < Disposable::Twin # i hate that so much. will we get namespace, ever?
  module Validate
    def validate
      validate!(nil).success?
    end

    def errors(*args)
      @result.errors(*args)
    end

    def validate!(name, pointers=[])
      puts ">>> #{name.inspect}"
      # puts "    #{pointers.inspect}"

      # TODO: rename to Groups::Validate
      # run local validations. this could be nested schemas, too.
      local_errors_by_group = Reform::Validation::Groups::Result.(self.class.validation_groups, self).compact # TODO: discss compact

      @result = Result.new(local_errors_by_group + pointers). tap do
        # blindly add injected pointers. will be readable via #errors.
        # also, add pointers from local errors here.
        pointers += local_errors_by_group.collect { |errs| Result::Pointer.new(errs, []) }.compact
        nested_errors = validate_nested!(pointers) # DISCUSS: do we need the nested errors right here?
      end

      # TODO: we're false if nested is false!
    end

  private

    # Recursively call validate! on nested forms.
    # A pointer keeps an entire result object (e.g. Dry result) and
    # the relevant path to its fragment, e.g. <Dry::result{.....} path=songs,0>
    def validate_nested!(pointers)
      schema.each(twin: true) do |dfn|
        # on collections, this calls validate! on each item form.
        Disposable::Twin::PropertyProcessor.new(dfn, self).() { |form, i|
          nested_pointers = pointers.collect { |pointer| pointer.advance(dfn[:name].to_sym, i) }.compact # pointer contains fragment for us, so go deeper

          form.validate!(dfn[:name], nested_pointers)
        }
      end
    end
  end
end
