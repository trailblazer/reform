module Reform::Contract::Validate
  attr_reader :errors # TODO: breaks when #validate wasn't called (and that's a GOOD THING.)

  def validate
    validate!.empty?
  end

  def validate!
    nested_errors = validate_nested!

    local_errors = Reform::Validation::Groups::Result.(self.class.validation_groups, self)

    nested_errors.each do |(name, errors)|
      local_errors.merge!(errors, name)
    end

    @errors = local_errors # @ivar sucks, of course
  end

private

  # Recursively call validate! on nested forms.
  # Collect [ [:composer, #<Errors>], [:albums, #<Errors>]]
  def validate_nested!
    arr = []
    schema.each(twin: true) do |dfn|
      Disposable::Twin::PropertyProcessor.new(dfn, self).() { |form| arr<<[ dfn[:name], form.validate! ] }
    end
    arr
  end
end
