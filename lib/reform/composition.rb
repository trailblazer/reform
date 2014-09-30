require 'disposable/composition'

# TODO: replace that with lazy Twin and Composition from Disposable.
module Reform
  class Expose
    include Disposable::Composition

    # DISCUSS: this might be moved to Disposable::Twin::Expose.
    class << self
      # Builder for a concrete Composition class with configurations from the form's representer.
      def from(representer)
        options = {}

        representer.representable_attrs.each do |definition|
          process_definition!(options, definition)
        end

        Class.new(self).tap do |composition| # for 1.8 compat. you're welcome.
          composition.map(options)
          # puts composition@map.inspect
        end
      end

    private
      def process_definition!(options, definition)
        options[:model] ||= []
        options[:model] << [definition[:private_name], definition.name].compact
      end
    end
  end

  # Keeps composition of models and knows how to transform a plain hash into a nested hash.
  class Composition < Expose

    # DISCUSS: this might be moved to Disposable::Twin::Composition.
    class << self
      # Builder for a concrete Composition class with configurations from the form's representer.
      def process_definition!(options, definition)
        options[definition[:on]] ||= []
        options[definition[:on]] << [definition[:private_name], definition.name].compact
      end
    end

    def save
      each.collect { |model| model.save }.all?
    end

    def nested_hash_for(attrs)
      {}.tap do |hsh|
        attrs.each do |name, val|
          #obj = self.class.model_for_property(name)
          config = self.class.instance_variable_get(:@map)[name.to_sym]

          model  = config[:model]
          method = config[:method]

          hsh[model] ||= {}
          hsh[model][method] = val
        end
      end
    end
  end
end
