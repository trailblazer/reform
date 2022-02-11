module Reform
  module Twin
    def self.add_property_to_twin!(name, twin, definitions, **kws)
      # For now, our "twin" is a cheap Struct.
      twin = Struct.new(*definitions.keys)

      twin
    end
  end
end
