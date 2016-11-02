# Adds ::validates and friends, and #valid? to the object.
# This is completely form-independent.
module Reform::Validation
  module ClassMethods
    def validation_groups
      @groups ||= Groups.new(validation_group_class) # TODO: inheritable_attr with Inheritable::Hash
    end

    # DSL.
    def validation(name=nil, options={}, &block)
      options = deprecate_validation_positional_args(name, options)
      name    = options[:name] # TODO: remove in favor of kw args in 3.0.

      heritage.record(:validation, options, &block)
      group = validation_groups.add(name, options)

      group.instance_exec(&block)
    end

    def deprecate_validation_positional_args(name, options)
      if name.is_a?(Symbol)
        warn "[Reform] Form::validation API is now: validation(name: :default, if:nil, schema:Schema). Please use keyword arguments instead of positional arguments."
        return { name: name }.merge(options)
      end

      if name.nil?
        return { name: :default }.merge(options)
      end

      { name: :default }.merge(name)
    end

    def validation_group_class
      raise NoBackendError, 'no validation backend loaded. Please include a ' +
                            'validation backend such as Reform::Form::Dry'
    end
  end

  def self.included(includer)
    includer.extend(ClassMethods)
  end

  def valid?
    Groups::Result.new(self.class.validation_groups).(self, errors)
  end

  class NoBackendError < RuntimeError
  end
end

require "reform/validation/groups"
