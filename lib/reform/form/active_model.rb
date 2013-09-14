module Reform::Form::ActiveModel
  module FormBuilderMethods # TODO: rename to FormBuilderCompat.
    def self.included(base)
      base.class_eval do
        extend ClassMethods # ::model_name
      end
    end

    module ClassMethods
      def property(name, options={})
        add_nested_attribute_compat(name) if block_given? # TODO: fix that in Rails FB#1832 work.
        super
      end

    private
      # The Rails FormBuilder "detects" nested attributes (which is what we want) by checking existance of a setter method.
      def add_nested_attribute_compat(name)
        define_method("#{name}_attributes=") {} # this is why i hate respond_to? in Rails.
      end
    end

    # Modify the incoming Rails params hash to be representable compliant.
    def validate(params)
      mapper.new(self).nested_forms do |attr, model| # FIXME: make this simpler.
        if attr.options[:form_collection] # FIXME: why no array?
          params[attr.name] = params["#{attr.name}_attributes"].values
        else
          params[attr.name] = params["#{attr.name}_attributes"]# DISCUSS: delete old key? override existing?
        end
      end

      super
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
    # Set a model name for this form if the infered is wrong.
    #
    #   class CoverSongForm < Reform::Form
    #     model :song
    def model(main_model, options={})
      @model_options = [main_model, options]  # FIXME: make inheritable!
    end

    def model_name
      if @model_options
        form_name = @model_options.first.to_s.camelize
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
