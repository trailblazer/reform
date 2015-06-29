module Reform::Form::MultiParameterAttributes
  # TODO: implement this with parse_filter, so we don't have to manually walk through the hash, etc.
  class DateTimeParamsFilter
    def call(params)
      params = params.dup # DISCUSS: not sure if that slows down form processing?
      date_attributes = {}

      params.each do |attribute, value|
        if value.is_a?(Hash)
          params[attribute] = call(value) # TODO: #validate should only handle local form params.
        elsif matches = attribute.match(/^(\w+)\(.i\)$/)
          date_attribute = matches[1]
          date_attributes[date_attribute] = params_to_date(
            params.delete("#{date_attribute}(1i)"),
            params.delete("#{date_attribute}(2i)"),
            params.delete("#{date_attribute}(3i)"),
            params.delete("#{date_attribute}(4i)"),
            params.delete("#{date_attribute}(5i)")
          )
        end
      end
      params.merge!(date_attributes)
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

  # this hooks into the format-specific #deserialize! method.
  def deserialize!(params)
    super DateTimeParamsFilter.new.call(params) # if params.is_a?(Hash) # this currently works for hash, only.
  end

  # module BuildDefinition
  #   def build_definition(name, options, &block)
  #     return super unless options[:multi_params]

  #     options[:parse_filter] << DateParamsFilter.new
  #     super
  #   end
  # end
end
