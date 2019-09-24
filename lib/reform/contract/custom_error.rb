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

      attr_reader :messages, :hint

      def success?
        false
      end

      def failure?
        true
      end

      # dry 1.x errors method has 1 kwargs argument
      def errors(**_args)
        @errors
      end

      def merge!
        # to_h required for dry_v 1.x since the errors are Dry object instead of an hash
        @results.map(&:errors)
                .detect { |hash| hash.to_h.key?(@key) }
                .tap { |hash| hash.nil? ? @results << self : hash.to_h[@key] |= Array(@error_text) }
      end
    end
  end
end
