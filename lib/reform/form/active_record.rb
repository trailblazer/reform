class Reform::Form
  module ActiveRecord

    def self.included(base)
      base.class_eval do
        include ActiveModel
        extend ClassMethods
      end
    end

    module ClassMethods
      def validates_uniqueness_of(attribute)
        validates_with UniquenessValidator, :attributes => [attribute]
      end
    end

    class UniquenessValidator < ::ActiveRecord::Validations::UniquenessValidator
      # when calling validates it should create the Vali instance already and set @klass there! # TODO: fix this in AM.
      def validate(form)
        property = attributes.first
        model_name = form.send(:model).class.model_for_property(property)

        # here is the thing: why does AM::UniquenessValidator require a filled-out record to work properly? also, why do we need to set
        # the class? it would be way easier to pass #validate a hash of attributes and get back an errors hash.
        # the class for the finder could either be infered from the record or set in the validator instance itself in the call to ::validates.
        record = form.send(model_name)
        record.send("#{property}=", form.send(property))
        @klass = record.class # this is usually done in the super-sucky #setup method.
        super(record).tap do |res|
          form.errors.add(property, record.errors.first.last) unless record.errors.blank?
        end
      end
    end
  end
end