class Reform::Form
  module MultiParameterAttributes
    class DateParamsFilter
      def call(params)
        date_attributes = {}

        params.each do |attribute, value|
          if value.is_a?(Hash)
            call(value) # TODO: #validate should only handle local form params.
          elsif matches = attribute.match(/^(\w+)\(.i\)$/)
            date_attribute = matches[1]
            date_attributes[date_attribute] = params_to_date(
              params.delete("#{date_attribute}(1i)"),
              params.delete("#{date_attribute}(2i)"),
              params.delete("#{date_attribute}(3i)")
            )
          end
        end
        params.merge!(date_attributes)
      end

    private
      def params_to_date(year, month, day)
        return nil if blank_date_parameter?(year, month, day)

        Date.new(year.to_i, month.to_i, day.to_i) rescue nil # reject invalid, like feb 31
      end

      def blank_date_parameter?(year, month, day)
        year.blank? || month.blank? || day.blank?
      end
    end

    def validate(params)
      # TODO: make it cleaner to hook into essential reform steps.
      DateParamsFilter.new.call(params)

      super
    end
  end
end