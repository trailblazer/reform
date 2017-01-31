module Reform::Contract::Validate
  def validate
    validate!(nil).success?
  end

  def errors(*args)
    @result.errors(*args)
  end

  def validate!(name, pointers=[])
    puts ">>> #{name.inspect}"

    # TODO: rename to Groups::Validate
    # run local validations. this could be nested schemas, too.
    local_errors_by_group = Reform::Validation::Groups::Result.(self.class.validation_groups, self).compact # TODO: discss compact

    @result = Reform::Contract::Result.new(local_errors_by_group + pointers). tap do # blindly add injected pointers. will be readable via #errors.
      pointers += [P.new(local_errors_by_group[0], [])]
      nested_errors = validate_nested!(pointers) # DISCUSS: do we need the nested errors right here?
    end

    # TODO: we're false if nested is false!
  end



  P = Reform::Contract::Result::Pointer

private

  # Recursively call validate! on nested forms.
  # A pointer keeps an entire result object (e.g. Dry result) and
  # the relevant path to its fragment, e.g. <Dry::result{.....} path=songs,0>
  def validate_nested!(pointers)
    schema.each(twin: true) do |dfn|
      # on collections, this calls validate! on each item form.
      Disposable::Twin::PropertyProcessor.new(dfn, self).() { |form, i|

        pointer = pointers[0] # FIXME.

        nested_pointers = [] # TODO: process all original pointers!
        if pointer && pointer[dfn[:name].to_sym] # pointer contains fragment for us, so go one deeper.

          # local error has a nested element for us!
          path = pointer.instance_variable_get(:@path)
          res = pointer.instance_variable_get(:@result)
          # puts "found (#{dfn[:name]}) #{nested_error}, #{path+[dfn[:name].to_sym, i].compact}x #{res}"

          nested_pointers << pointer.advance([ dfn[:name].to_sym, i ])
        end

        form.validate!(dfn[:name], nested_pointers.compact)
      }
    end
  end
end
