module Reform::Form::ActiveModel
  # Including FormBuilderMethods will allow using form instances with form_for, simple_form, etc.
  # in Rails. It will further try to translate Rails' suboptimal songs_attributes weirdness
  # back to normal `songs: ` naming in +#valiate+.
  module FormBuilderMethods
    def self.included(base)
      base.extend ClassMethods # ::model_name
    end

    module ClassMethods
    private

      # TODO: add that shit in Form#present, not by overriding ::property.
      def property(name, options={}, &block)
        super.tap do |definition|
          add_nested_attribute_compat(name) if definition[:nested] # TODO: fix that in Rails FB#1832 work.
        end
      end

      # The Rails FormBuilder "detects" nested attributes (which is what we want) by checking existance of a setter method.
      def add_nested_attribute_compat(name)
        define_method("#{name}_attributes=") {} # this is why i hate respond_to? in Rails.
      end
    end

    # Modify the incoming Rails params hash to be representable compliant.
    def deserialize!(params)
      # this only happens in a Hash environment. other engines have to overwrite this method.
      schema.each do |dfn|
        rename_nested_param_for!(params, dfn)
      end

      super(params)
    end

  private
    def rename_nested_param_for!(params, dfn)
      name        = dfn[:name]
      nested_name = "#{name}_attributes"
      return unless params.has_key?(nested_name)

      value = params["#{name}_attributes"]
      value = value.values if dfn[:collection]

      params[name] = value
    end
  end
end