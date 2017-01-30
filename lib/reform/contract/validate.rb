module Reform::Contract::Validate
  attr_reader :errors # TODO: breaks when #validate wasn't called (and that's a GOOD THING.)

  def validate
    validate!(nil, {}).success?
  end

  def validate!(name, injected_errors)
    # injected_errors: {:name=>["must be filled"], :label=>{:location=>["must be filled"]}}
    puts ">>> #{name.inspect}, #{injected_errors}"


    local_errors_by_group = Reform::Validation::Groups::Result.(self.class.validation_groups, self).compact # TODO: discss compact




        nested_errors = validate_nested!({})
return @errors = local_errors


    local_errors = Reform::Contract::Errors.new

    # merge injected locals on local.
    Reform::Contract::Errors::Merge.(local_errors, injected_errors, [])

    # validate local validation groups.
    local_errors_by_group = Reform::Validation::Groups::Result.(self.class.validation_groups, self).compact # TODO: discss compact

    nested_injected_errors = {}.merge(injected_errors)

    local_errors_by_group.each do |error|
      # dry:
      error = error.instance_variable_get(:@original_result)

      Reform::Contract::Errors::Merge.(local_errors, error.messages, [])

      nested_injected_errors.merge!(error.messages)
    end

    nested_errors = validate_nested!(nested_injected_errors)

    # this is where nested dry errors come with mixed validations.

    nested_errors.each do |(prefixes, errors)|
      Reform::Contract::Errors::Merge.(local_errors, errors.messages, prefixes)
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
