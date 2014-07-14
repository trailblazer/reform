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
        namespaced_attributes = attributes.map do |attribute|
          [model_name, attribute].compact
        end
        @mapping.inverse_map(namespaced_attributes)
      end

    end

    class Mapping
      def self.from_representable_attrs(attrs)
        new.tap do |mapping|
          attrs.to_a.each do |(key,value)|
            from = key.to_sym
            to = [value[:on], (value[:private_name] || key)].compact.map(&:to_sym)
            mapping.add(from, to)
          end
        end
      end

      def initialize
        @mapping = []
        generate_indexes
      end

      # from is a symbol
      # to is an 1 or 2 element array, depending on whether the attribute is 'namespaced', as it is with composite forms.
      def add(from, to)
        raise 'Mapping is not one-to-one' if @forward_map.has_key?(from) || @inverse_map.has_key?(to)
        @mapping << [from, to]
        generate_indexes
      end

      def forward_map(attrs)
        attrs.map do |attr|
          forward(attr)
        end.compact
      end

      def forward(attr)
        @forward_map[attr]
      end

      def inverse_map(attrs)
        attrs.map do |attr|
          inverse(attr)
        end.compact
      end

      def inverse(attr)
        @inverse_map[attr]
      end

    private

      def generate_indexes
        generate_forward_map
        generate_inverse_map
      end

      def generate_forward_map
        @forward_map = Hash[@mapping]
      end

      def generate_inverse_map
        @inverse_map = Hash[@mapping.map { |(from, to)| [to, from] }]
      end
    end

    def copy_validations_from(models)
      ValidationCopier.new(self, Mapping.from_representable_attrs(representer_class.representable_attrs)).copy_from(models)
    end

  end
end