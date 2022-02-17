module Reform
  class Form
    # @Runtime
    # Runtime form object returned after {Reform.deserialize}.
    class Deserialized
      def initialize(schema, form, populated_instance, arbitrary_bullshit)
        @schema             = schema
        @form               = form
        @populated_instance = populated_instance # populated_instance
        @arbitrary_bullshit = arbitrary_bullshit # ctx of the PPP
      end

      def method_missing(name, *args) # DISCUSS: no setter?
        return @populated_instance[name] if @schema.key?(name) # this method is referring to a property of our holy form (e.g. {#band}).

        @form.send(name, *args)
      end

      def [](name)
        @arbitrary_bullshit[name]
      end

      def []=(name, value) # DISCUSS: is this our official setter when you don't want to parse-populate?
        @populated_instance[name] = value
      end


      def to_input_hash
        @populated_instance # FIXME: this still contains nested forms!
      end
    end
  end
end
