module Reform::Form::ActiveModel
  module ModelValidations
    # TODO: extract Composition behaviour.
    # reduce code in Mapping.

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
          @form_class.validates(*attributes, {validator.kind => validator.options})
        end
      end

      def map_attributes(attributes, model_name=nil)
        namespaced_attributes = attributes.map do |attribute|
          [model_name, attribute].compact
        end
        @mapping.inverse_image(namespaced_attributes)
      end

    end

    class Mapping
      def self.from_representable_attrs(attrs)
        new.tap do |mapping|
          attrs.each do |dfn|
            from = dfn.name.to_sym
            to = [dfn[:on], (dfn[:private_name] || dfn.name)].compact.map(&:to_sym)
            mapping.add(from, to)
          end
        end
      end

      def initialize
        @forward_map = {}
        @inverse_map = {}
      end

      # from is a symbol attribute
      # to is an 1 or 2 element array, depending on whether the attribute is 'namespaced', as it is with composite forms.
      # eg, add(:phone_number, [:person, :phone])
      def add(from, to)
        raise 'Mapping is not one-to-one' if @forward_map.has_key?(from) || @inverse_map.has_key?(to)
        @forward_map[from] = to
        @inverse_map[to] = from
      end

      def forward_image(attrs)
        @forward_map.values_at(*attrs).compact
      end

      def forward(attr)
        @forward_map[attr]
      end

      def inverse_image(attrs)
        @inverse_map.values_at(*attrs).compact
      end

      def inverse(attr)
        @inverse_map[attr]
      end

    end

    def copy_validations_from(models)
      ValidationCopier.new(self, Mapping.from_representable_attrs(representer_class.representable_attrs)).copy_from(models)
    end

  end
end