module Reform::Contract::Validate
  attr_reader :errors # TODO: breaks when #validate wasn't called (and that's a GOOD THING.)

  def validate
    validate!(nil, {}).success?
  end


  # first: nested schema needs to write errors to nested forms
  # second: normal mechanics: validate all nested forms, merge their errors into ours.

  def validate!(name, injected_errors)
    puts ">>> #{name.inspect}, #{injected_errors}"

    local_errors_by_group = Reform::Validation::Groups::Result.(self.class.validation_groups, self).compact # TODO: discss compact
    puts "  > #{local_errors_by_group.inspect}" # validate_nested!(:songs-1 Error)

    nested_passthrough_errors = {}.merge(injected_errors)

    local_errors = Reform::Contract::Errors.new
    Reform::Contract::Errors::Merge.merge!(local_errors, injected_errors, []) # merge injected on local.

    local_errors_by_group.each do |error|
      # dry:
      error = error.instance_variable_get(:@original_result)

      Reform::Contract::Errors::Merge.merge!(local_errors, error.messages, [])

      nested_passthrough_errors.merge!(error.messages)
    end

    # dry:
    puts "@@@@@ #{nested_passthrough_errors.inspect}"

    nested_errors = validate_nested!(nested_passthrough_errors)

    # this is where nested dry errors come with mixed validations.
    # this is also where fran's algorithm set errors on nested forms.



    nested_errors.each do |(prefixes, errors)|
      Reform::Contract::Errors::Merge.merge!(local_errors, errors.messages, prefixes)
    end

    @errors = local_errors # @ivar sucks, of course
  end

private

  # Recursively call validate! on nested forms.
  # Collect [ [:composer, #<Errors>], [:albums, #<Errors>]]
  def validate_nested!(errors_by_form)
    arr = []
    schema.each(twin: true) do |dfn|
      # on collections, this calls validate! on each item form.
      Disposable::Twin::PropertyProcessor.new(dfn, self).() { |form, i|
        passthrough_errors = errors_by_form[dfn[:name].to_sym] ||{} # dry
        passthrough_errors = passthrough_errors[i] || {} if i

        arr<<[ [dfn[:name], i], form.validate!(dfn[:name], passthrough_errors) ] }
    end
    arr
  end
end
