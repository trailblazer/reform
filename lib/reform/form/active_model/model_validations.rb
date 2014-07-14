module Reform::Form::ActiveModel
  module ModelValidations

    class ValidationCopier

      def initialize(form_class, mapping)
        @form_class = form_class
        @mapping = mapping
      end

      def copy_from(models)
        if models.is_a?(Hash)
          models.each do |model_name, model|
            copy_from_model(model, model_name)
          end
        else
          copy_from_model(models)
        end
      end



      def copy_from_model(model, model_name=nil)
        model.validators.each do |validator|
          add_validator(validator, model_name)
        end
      end

    private

      def add_validator(validator, model_name=nil)
        attributes = map_attributes(validator.attributes, model_name)
        if attributes.any?
          @form_class.instance_eval do
            validates(*attributes, {validator.kind => validator.options})
          end
        end
      end

      def map_attributes(attributes, model_name=nil)
        attributes.map do |attribute|
          map_attribute(attribute, model_name)
        end.compact
      end

      def map_attribute(attribute_from, model_name=nil)
        attribute_to = @mapping.to_a.find do |(key, value)|
          ((value[:private_name] || key).to_sym == attribute_from.to_sym) && (model_name.nil? || model_name == value[:on])
        end

        attribute_to.nil? ? nil : attribute_to.first
      end

    end

    def copy_validations_from(models)
      ValidationCopier.new(self, representer_class.representable_attrs).copy_from(models)
    end

  end
end