require "lotus/validations"

module Reform::Form::Lotus
  class Errors < Lotus::Validations::Errors
    def merge!(errors, prefix)
      errors.errors.each do |err|
        field = (prefix+[err.attribute]).join(".")
        add(field, err) # TODO: use namespace feature in Lotus here!
      end
      #   next if messages[field] and messages[field].include?(msg)
    end

    def inspect
      @errors.to_s
    end

    def messages
      self
    end


  end


  def self.included(base)
    # base.send(:include, Lotus::Validations)
    base.extend(ClassMethods)
    # base.send(:include, Reform::Contract::Validate)
  end


  module ClassMethods
    def validates(name, options)
      validations.add(name, options)
    end

    def validations
      @validations ||= Lotus::Validations::ValidationSet.new
    end
  end


  def valid?
    # DISCUSS: by using @fields here, we avoid setters being called. win!
    validator = Lotus::Validations::Validator.new(self.class.validations, @fields, errors)
    validator.validate
  end

  def errors_for_validate
    Errors.new
  end
end