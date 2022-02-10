# This is completely validation backend-independent.
module Reform::Form::DSL
  module Validation
    def self.extended(extender)
      extender.state.add!("artifact/validation_groups", Reform::Validation::Groups.new) # FIXME: inheriting this is important
    end

    def validation_groups # FIXME: where do we need this?
      state.get("artifact/validation_groups")
    end

    # DSL.
    def validation(name:, group_class:, **options, &block)
      group = group_class.new(options)
      group.instance_exec(&block)

      # heritage.record(:validation, options, &block)
      state.update!("artifact/validation_groups") { validation_groups.add(name, options, group) }
    end
  end


  # def validation_group_class
  #   raise NoValidationLibraryError, "no validation library loaded. Please include a " +
  #                                   "validation library such as Reform::Form::Dry"
  # end

  # NoValidationLibraryError = Class.new(RuntimeError)
end


