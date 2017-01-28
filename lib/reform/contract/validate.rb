module Reform::Contract::Validate
  # def initialize(*)
  #   super
  #   @errors = build_errors
  # end

  attr_reader :errors

  def validate
    errors = validate!([])

    errors.empty?
  end

  def validate!(prefix)
    validate_nested!(prefix)

    local_errors = build_errors
    Reform::Validation::Groups::Result.(self.class.validation_groups, self, local_errors)







    @errors = local_errors # @ivar sucks, of course

    # Group.() #=> errs={title: "bla wrong"}
    # @errors = errs
    # @errors, nested_errors = validate_branch(prefix)

    # puts "----> #{@errors}"
    # puts "----> #{nested_errors}"


    # errors.merge!(@errors, prefix) # local errors.
    # errors.merge!(nested_errors, [])

    @errors
  end

  # TODO: make build_errors a lambda.
  # def validate_branch(prefix)
  #   validate_nested!(nested_errors = build_errors, prefix)



  #   [local_errors, nested_errors]
  # end

private

  # runs form.validate! on all nested forms
  def validate_nested!(prefixes)
    schema.each(twin: true) do |dfn|
      # recursively call valid? on nested form.
      Disposable::Twin::PropertyProcessor.new(dfn, self).() { |form| form.validate!(prefixes+[dfn[:name]]) }
    end
  end
end
