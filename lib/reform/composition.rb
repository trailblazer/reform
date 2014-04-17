module Reform
  # Keeps composition of models and knows how to transform a plain hash into a nested hash.
  class Composition
    require 'disposable/composition' # FIXME: what about autoloading?
    include Disposable::Composition

    class << self
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
  end
end