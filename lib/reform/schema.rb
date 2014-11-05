module Reform
  module Schema
    # Converts the Representer->Form->Representer->Form tree into Representer->Representer.
    # It becomes obvious that the form will be the main schema-defining instance in Trb, so this
    # method makes sense. Consider private. This is experimental.
    #
    # This allows generating representers from forms. As you can see, only little code is needed thanks to representable.
    class Converter
      def self.from(representer_class) # TODO: can we re-use this for all the decorator logic in #validate, etc?
        representer = Class.new(representer_class)
        representer.representable_attrs.each do |dfn|
          next unless form = dfn[:form]

          dfn.merge!(:extend => from(form.representer_class))
          dfn.delete!(:prepare) # not sure if this is gonna stay. also, this is representable 2.1, only.
        end

        representer
      end
    end

    # It's your job to make sure you memoize it correctly.
    def schema
      Converter.from(representer_class)
    end
  end
end
