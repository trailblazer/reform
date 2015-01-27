Reform::Form.class_eval do
  module MultiParameterAttributes
    def self.included(base)
      base.send(:register_feature, self)
    end

    class DateTimeParamsFilter
      def call(params)
        params.each_with_object({}) do |(attribute, value), hsh|
          if value.is_a?(Hash)
            hsh[attribute] = call(value) # TODO: #validate should only handle local form params.
          elsif matches = attribute.match(/^(\w+)\(.i\)$/)
            date_attribute = matches[1]

            unless hsh.key?(date_attribute)
              hsh[date_attribute] = params_to_date(
                params["#{date_attribute}(1i)"],
                params["#{date_attribute}(2i)"],
                params["#{date_attribute}(3i)"],
                params["#{date_attribute}(4i)"],
                params["#{date_attribute}(5i)"]
              )
            end
          else
            hsh[attribute] = value
          end
        end
      end

    private
      def params_to_date(year, month, day, hour, minute)
        return nil if [year, month, day].any?(&:blank?)

        if hour.blank? && minute.blank?
          Date.new(year.to_i, month.to_i, day.to_i) # TODO: test fails.
        else
          args = [year, month, day, hour, minute].map(&:to_i)
          Time.zone ? Time.zone.local(*args) :
            Time.new(*args)
        end
      end
    end

    def validate(params)
      # TODO: make it cleaner to hook into essential reform steps.
      # TODO: test with nested.
      params = DateTimeParamsFilter.new.call(params) if params.is_a?(Hash) # this currently works for hash, only.

      super
    end


    # module ClassMethods
    #   def representer_class # TODO: check out how we can utilise Config#features.
    #     super.class_eval do
    #       extend BuildDefinition
    #       self
    #     end
    #   end
    # end


    # module BuildDefinition
    #   def build_definition(name, options, &block)
    #     return super unless options[:multi_params]

    #     options[:parse_filter] << DateParamsFilter.new
    #     super
    #   end
    # end
  end
end
