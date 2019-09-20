module Reform
  class Contract < Disposable::Twin
    # a "fake" Dry schema object to add into the @results array
    # super ugly hack required for 2.3.x version since we are creating
    # a new Reform::Errors instance every time we call form.errors
    class CustomError
      def initialize(key, error_text, results)
        @key        = key
        @error_text = error_text
        @errors     = {key => Array(error_text)}
        @messages   = @errors
        @hint       = {}
        @results    = results

        merge!
      end

      attr_reader :errors, :messages, :hint

      def success?
        false
      end

      def failure?
        true
      end

      def merge!
        @results.map(&:errors)
                .detect { |hash| hash.key?(@key) }
                .tap { |hash| hash.nil? ? @results << self : hash[@key] |= Array(@error_text) }
      end
    end
  end
end
