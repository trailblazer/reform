module Reform::Form::ActiveModel
  module ModelValidations
    # TODO: extract Composition behaviour.
    # reduce code in Mapping.

    class ValidationCopier

      def self.copy(form_class, mapping, models)
        if models.is_a?(Hash)
          models.each do |model_name, model|
            new(form_class, mapping, model, model_name).copy
          end
        else
          new(form_class, mapping, models).copy
        end
      end

      def initialize(form_class, mapping, model, model_name=nil)
        @form_class = form_class
        @mapping = mapping
        @model = model
        @model_name = model_name
      end

      def copy
        @model.validators.each(&method(:add_validator))
      end

    private

      def add_validator(validator)
        if validator.respond_to?(:attributes)
          add_native_validator validator
        else
          add_custom_validator validator
        end
      end

      def add_native_validator validator
        attributes = inverse_map_attributes(validator.attributes)
        if attributes.any?
          @form_class.validates(*attributes, {validator.kind => validator.options})
        end
      end

      def add_custom_validator validator
        @form_class.validates(nil, {validator.kind => validator.options})
      end

      def inverse_map_attributes(attributes)
        @mapping.inverse_image(create_attributes(attributes))
      end

      def create_attributes(attributes)
        attributes.map do |attribute|
          [@model_name, attribute].compact
        end
      end

    end

    class Mapping
      def self.from_representable_attrs(attrs)
        new.tap do |mapping|
          attrs.each do |dfn|
            from = dfn[:name].to_sym
            to = [dfn[:on], (dfn[:private_name] || dfn[:name])].compact.map(&:to_sym)
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
      ValidationCopier.copy(self, Mapping.from_representable_attrs(definitions), models)
    end

  end
end
