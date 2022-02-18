module Reform
  class Form
    module Sync
      module_function

      # CURRENTLY: write deserialized values from {Deserialized} forms to their twin pendants.
      # DISCUSS: With ROM we could create a Changeset here?
      def call(deserialized_form, schema: deserialized_form.instance_variable_get(:@form).schema)
        twin               = deserialized_form.instance_variable_get(:@form) # FIXME

        Contract::Validate.iterate_nested(deserialized_form: deserialized_form, schema: schema, only_twin: false) do |property_value, i:, definition:, **|
          # Here we iterate all local propertys, including nested forms

# DISCUSS: We are assuming that for each nested form instance we have a matching twin instance. the populators need to take care of that!
          if definition[:nested]
            call(property_value)
          else
            puts " ++ @@@@@ #{definition[:name]} = #{property_value}"
            twin.send("#{definition[:name]}=", property_value)
          end
        end

        twin
      end
    end # Sync

    def self.Sync(deserialized_form)
      Sync.(deserialized_form).sync# Disposable speaking.
    end

    def self.Save(deserialized_form)
      Sync.(deserialized_form).save# Disposable speaking.
    end
  end

end
