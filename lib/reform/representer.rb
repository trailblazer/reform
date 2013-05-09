require 'representable/hash'

module Reform
  class Representer < Representable::Decorator
    include Representable::Hash

    def self.properties(names, *args)
      names.each do |name|
        property(name, *args)
      end
    end

    # Returns hash of all property names.
    def fields
      representable_attrs.collect { |cfg| cfg.name }
    end
  end
end
