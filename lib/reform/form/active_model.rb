require "reform/form/active_model/model_validations"
require "reform/form/active_model/form_builder_methods"
require "uber/delegates"

module Reform::Form::ActiveModel
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
