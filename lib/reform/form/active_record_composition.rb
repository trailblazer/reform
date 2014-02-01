class Reform::Form
  module ActiveRecordComposition
    def self.included(base)
      base.class_eval do
        include Composition
      end
    end

    def save(*)
      save_to_models
      super do
        save_models unless block_given?
      end
    end

    def model_for_property(name)
      model_name = mapper.representable_attrs[name].options[:on]
      send(model_name)
    end

  private
    def save_models
      model.models.each { |m| m.save }
    end
  end
end
