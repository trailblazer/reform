class Reform::Form
  module ActiveRecordComposition
    def self.included(base)
      base.class_eval do
        include Composition
      end
    end

    def save(*)
      save_to_models
      super do |data, nested|
        block_given? ? yield(data, nested) : save_models
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
