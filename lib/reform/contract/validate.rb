module Reform::Contract::Validate
  # def initialize(*)
  #   super
  #   @errors = build_errors
  # end

  attr_reader :errors # TODO: breaks when #validate wasn't called (and that's a GOOD THING.)

  def validate
    errors = validate!

    errors.empty?
  end

  def validate!
    nested = validate_nested!

    local_errors = build_errors
    Reform::Validation::Groups::Result.(self.class.validation_groups, self, local_errors)

    nested.each do |(name, errors)|
      local_errors.merge!(errors, [name])
    end

    @errors = local_errors # @ivar sucks, of course
  end

  # TODO: make build_errors a lambda.

private

  # runs form.validate! on all nested forms
  def validate_nested!
    arr = []
    schema.each(twin: true) do |dfn|
      # recursively call valid? on nested form.
      Disposable::Twin::PropertyProcessor.new(dfn, self).() { |form| arr << [dfn[:name], form.validate!] }
    end

    arr
  end
end
