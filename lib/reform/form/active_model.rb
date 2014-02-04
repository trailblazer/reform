module Reform::Form::ActiveModel
  module FormBuilderMethods # TODO: rename to FormBuilderCompat.
    def self.included(base)
      base.class_eval do
        extend ClassMethods # ::model_name
      end
    end

    module ClassMethods
      def property(name, options={})
        super
        add_nested_attribute_compat(name) if options[:form] # TODO: fix that in Rails FB#1832 work.
      end

    private
      # The Rails FormBuilder "detects" nested attributes (which is what we want) by checking existance of a setter method.
      def add_nested_attribute_compat(name)
        define_method("#{name}_attributes=") {} # this is why i hate respond_to? in Rails.
      end
    end

    # Modify the incoming Rails params hash to be representable compliant.
    def validate(params)
      # DISCUSS: #validate should actually expect the complete params hash and then pick the right key as it knows the form name.
      # however, this would cause confusion?
      mapper.new(self).nested_forms do |attr, model| # FIXME: make this simpler.
        rename_nested_param_for!(params, attr)
      end

      super
    end

  private
    def rename_nested_param_for!(params, attr)
      nested_name = "#{attr.name}_attributes"
      return unless params.has_key?(nested_name)

      value = params["#{attr.name}_attributes"]
      value = value.values if attr.options[:form_collection]

      params[attr.name] = value
    end
  end


  def self.included(base)
    base.class_eval do
      extend ClassMethods

      delegate [:persisted?, :to_key, :to_param, :id] => :model

      def to_model # this is called somewhere in FormBuilder and ActionController.
        self
      end
    end
  end

  module ClassMethods
    def model_options
      return @model_options unless superclass.respond_to?(:model_options) and value = superclass.model_options
      @model_options ||= value.clone
    end

    def model_options=(value)
      @model_options = value
    end

    # Set a model name for this form if the infered is wrong.
    #
    #   class CoverSongForm < Reform::Form
    #     model :song
    def model(main_model, options={})
      self.model_options = [main_model, options]
    end

    def model_name
      if self.model_options
        form_name = self.model_options.first.to_s.camelize
      else
        form_name = name.sub(/Form$/, "")
      end

      active_model_name_for(form_name)
    end

  private
    def active_model_name_for(string)
      return ::ActiveModel::Name.new(OpenStruct.new(:name => string)) if Reform.rails3_0?
      ::ActiveModel::Name.new(self, nil, string)
    end
  end
end
