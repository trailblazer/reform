require "reform/form/active_model/model_validations"
require "uber/delegates"

module Reform::Form::ActiveModel
  module FormBuilderMethods # TODO: rename to FormBuilderCompat.
    def self.included(base)
      base.extend ClassMethods # ::model_name
    end

    module ClassMethods
    private

      # TODO: add that shit in Form#present, not by overriding ::property.
      def property(name, options={}, &block)
        super.tap do |definition|
          add_nested_attribute_compat(name) if definition[:twin] # TODO: fix that in Rails FB#1832 work.
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
      nested_name = "#{dfn.name}_attributes"
      return unless params.has_key?(nested_name)

      value = params["#{dfn.name}_attributes"]
      value = value.values if dfn[:collection]

      params[dfn.name] = value
    end
  end # FormBuilderMethods


  def self.included(base)
    base.class_eval do
      extend ClassMethods
      register_feature ActiveModel

      extend Uber::Delegates
      delegates :model, *[:persisted?, :to_key, :to_param, :id] # Uber::Delegates

      def to_model # this is called somewhere in FormBuilder and ActionController.
        self
      end
    end
  end


  module ClassMethods
    # this module is only meant to extend (not include). # DISCUSS: is this a sustainable concept?
    def self.extended(base)
      base.class_eval do
        extend Uber::InheritableAttribute
        inheritable_attr :model_options
      end
    end


    # Set a model name for this form if the infered is wrong.
    #
    #   class CoverSongForm < Reform::Form
    #     model :song
    #
    # or we can setup a isolated namespace model ( which defined in isolated rails egine )
    #
    #   class CoverSongForm < Reform::Form
    #     model "api/v1/song", namespace: "api"
    def model(main_model, options={})
      self.model_options = [main_model, options]
    end

    def model_name
      if model_options
        form_name = model_options.first.to_s.camelize
        namespace = model_options.last[:namespace].present? ? model_options.last[:namespace].to_s.camelize.constantize : nil
      else
        form_name = name.sub(/(::)?Form$/, "") # Song::Form => "Song"
        namespace = nil
      end

      active_model_name_for(form_name, namespace)
    end

  private
    def active_model_name_for(string, namespace=nil)
      return ::ActiveModel::Name.new(OpenStruct.new(:name => string)) if Reform.rails3_0?
      ::ActiveModel::Name.new(self, namespace, string)
    end
  end # ClassMethods


  def model_name(*args)
    self.class.model_name(*args)
  end
end
