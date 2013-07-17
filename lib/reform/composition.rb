module Reform
  # Keeps composition of models and knows how to transform a plain hash into a nested hash.
  class Composition
    class << self
      def map(options)
        @attr2obj = {}  # {song: ["title", "track"], artist: ["name"]}

        options.each do |mdl, meths|
          create_accessors(mdl, meths)
          attr_reader mdl

          meths.each { |m| @attr2obj[m.to_s] = mdl }
        end
      end

      # Specific to representable.
      def map_from(representer)
        options = {}
        representer.representable_attrs.each do |cfg|
          options[cfg.options[:on]] ||= []
          options[cfg.options[:on]] << cfg.name
        end

        map options
      end

      def model_for_property(name)
        @attr2obj.fetch(name.to_s)
      end

    private
      def create_accessors(model, methods)
        accessors = methods.collect { |m| [m, "#{m}="] }.flatten
        delegate *accessors << {:to => :"#{model}"}
      end
    end

    # TODO: make class method?
    def nested_hash_for(attrs)
      {}.tap do |hsh|
        attrs.each do |name, val|
          obj = self.class.model_for_property(name)
          hsh[obj] ||= {}
          hsh[obj][name.to_sym] = val
        end
      end
    end

    def initialize(models)
      models.each do |name, obj|
        instance_variable_set(:"@#{name}", obj)
      end
    end
  end
end