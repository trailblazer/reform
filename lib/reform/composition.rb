require 'disposable/composition'

module Reform
  class Expose
    include Disposable::Composition

    # DISCUSS: this might be moved to Disposable::Twin::Expose.
    class << self
      # Builder for a concrete Composition class with configurations from the form's representer.
      def from(representer)
        options = {}

        representer.representable_attrs.each do |cfg|
          process_for!(options, cfg)
        end

        Class.new(self).tap do |composition| # for 1.8 compat. you're welcome.
          composition.map(options)
          # puts composition@map.inspect
        end
      end

    private
      def process_for!(options, cfg)
        options[:model] ||= []
        options[:model] << [cfg[:private_name], cfg.name].compact
      end
    end
  end

  # Keeps composition of models and knows how to transform a plain hash into a nested hash.
  class Composition < Expose

    # DISCUSS: this might be moved to Disposable::Twin::Composition.
    class << self
      # Builder for a concrete Composition class with configurations from the form's representer.
      def process_for!(options, cfg)
        options[cfg[:on]] ||= []
        options[cfg[:on]] << [cfg[:private_name], cfg.name].compact
      end
    end

    def save
      each { |model| model.save }
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