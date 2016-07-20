# Adds ::validates and friends, and #valid? to the object.
# This is completely form-independent.
module Reform::Validation
  module ClassMethods
    def validation_groups
      @groups ||= Groups.new(validation_group_class) # TODO: inheritable_attr with Inheritable::Hash
    end

    # DSL.
    def validation(name=:default, options={}, &block)
      heritage.record(:validation, name, options, &block)

      group = validation_groups.add(name, options)

      group.instance_exec(&block)
    end

    def validates(*args, &block)
      validation(:default, inherit: true) { validates *args, &block }
    end

    def validate(*args, &block)
      validation(:default, inherit: true) { validate *args, &block }
    end

    def validates_with(*args, &block)
      validation(:default, inherit: true) { validates_with *args, &block }
    end
  end

  def self.included(includer)
    includer.extend(ClassMethods)
  end

  def valid?
    Groups::Result.new(self.class.validation_groups).(to_nested_hash, errors, self)
  end
end

require "reform/validation/groups"
