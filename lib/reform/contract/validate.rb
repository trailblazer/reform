module Reform::Contract::Validate
  attr_reader :errors # TODO: breaks when #validate wasn't called (and that's a GOOD THING.)

  def validate
    validate!.success?
  end

  def validate!
    nested_errors = validate_nested!

    local_errors_by_group = Reform::Validation::Groups::Result.(self.class.validation_groups, self).compact # TODO: discss compact

    local_errors = Reform::Contract::Errors.new
    local_errors_by_group.each do |error|
       Reform::Contract::Errors::Merge.merge!(local_errors, error, [])
    end


    nested_errors.each do |(prefixes, errors)|
      Reform::Contract::Errors::Merge.merge!(local_errors, errors, prefixes)
    end

    @errors = local_errors # @ivar sucks, of course
  end

private

  # Recursively call validate! on nested forms.
  # Collect [ [:composer, #<Errors>], [:albums, #<Errors>]]
  def validate_nested!
    arr = []
    schema.each(twin: true) do |dfn|
      # on collections, this calls validate! on each item form.
      Disposable::Twin::PropertyProcessor.new(dfn, self).() { |form, i| arr<<[ [dfn[:name], i], form.validate! ] }
    end
    arr
  end
end
