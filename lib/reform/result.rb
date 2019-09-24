module Reform
  class Contract < Disposable::Twin
    # Collects all native results of a form of all groups and provides
    # a unified API: #success?, #errors, #messages, #hints.
    # #success? returns validity of the branch.
    class Result
      def initialize(results, nested_results = []) # DISCUSS: do we like this?
        @results = results # native Result objects, e.g. `#<Dry::Validation::Result output={:title=>"Fallout", :composer=>nil} errors={}>`
        @failure = (results + nested_results).find(&:failure?) # TODO: test nested.
      end

      def failure?; @failure  end

      def success?; !failure? end

      def errors(*args);   filter_for(:errors, *args) end

      def messages(*args); filter_for(:messages, *args) end

      def hints(*args);    filter_for(:hints, *args) end

      def add_error(key, error_text)
        CustomError.new(key, error_text, @results)
      end

      def to_results
        @results
      end

      private

      # this doesn't do nested errors (e.g. )
      def filter_for(method, *args)
        @results.collect { |r| r.public_send(method, *args).to_h }
                .inject({}) { |hah, err| hah.merge(err) { |key, old_v, new_v| (new_v.is_a?(Array) ? (old_v |= new_v) : old_v.merge(new_v)) } }
                .find_all { |k, v| # filter :nested=>{:something=>["too nested!"]} #DISCUSS: do we want that here?
                  if v.is_a?(Hash)
                    nested_errors = v.select { |attr_key, val| attr_key.is_a?(Integer) && val.is_a?(Array) && val.any? }
                    v = nested_errors.to_a if nested_errors.any?
                  end
                  v.is_a?(Array)
                }.to_h
      end

      # Note: this class will be redundant in Reform 3, where the public API
      # allows/enforces to pass options to #errors (e.g. errors(locale: "br"))
      # which means we don't have to "lazy-handle" that with "pointers".
      # :private:
      class Pointer
        extend Forwardable

        def initialize(result, path)
          @result, @path = result, path
        end

        def_delegators :@result, :success?, :failure?

        def errors(*args);   traverse_for(:errors, *args) end

        def messages(*args); traverse_for(:messages, *args) end

        def hints(*args);    traverse_for(:hints, *args) end

        def advance(*path)
          path = @path + path.compact # remove index if nil.
          traverse = traverse(@result.errors, path)
          # when returns {} is because no errors are found
          # when returns a String is because an error has been found on the main key not in the nested one.
          #   Collection with custom rule will return a String here and does not need to be considered
          #   as a nested error.
          # when return an Array without an index is same as String but it's a property with a custom rule.
          # Check test/validation/dry_validation_test.rb:685
          return if traverse == {} || traverse.is_a?(String) || (traverse.is_a?(Array) && path.compact.size == 1)

          Pointer.new(@result, path)
        end

        private

        def traverse(hash, path)
          path.inject(hash) { |errs, segment| errs[segment] || {} } # FIXME. test if all segments present.
        end

        def traverse_for(method, *args)
          traverse(@result.public_send(method, *args), @path) # TODO: return [] if nil
        end
      end
    end
  end
end
