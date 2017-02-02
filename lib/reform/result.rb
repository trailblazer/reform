module Reform
  class Contract < Disposable::Twin

    # Collects all results of a form of all groups.
    # Keeps the validity of that branch.
    class Result
      def initialize(results, nested_results=[]) # DISCUSS: do we like this?
        @results = results
        @failure = (results + nested_results).find(&:failure?) # TODO: test nested.
      end

      def success?
        ! failure?
      end

      def failure?
        @failure
      end

      def errors(*args)
        @results.collect { |r| r.errors(*args) }
          .inject({}) { |hsh, errs| hsh.merge(errs) }
          .find_all { |k, v| v.is_a?(Array) } # filter :nested=>{:something=>["too nested!"]} #DISCUSS: do we want that here?
          .to_h
      end

      def messages(*args) # FIXME
        @results.collect { |r| r.messages(*args) }
          .inject({}) { |hsh, errs| hsh.merge(errs) }
          .find_all { |k, v| v.is_a?(Array) } # filter :nested=>{:something=>["too nested!"]} #DISCUSS: do we want that here?
          .to_h
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

        def errors(*args)
          traverse(@result.errors(*args), @path) # TODO: return [] if nil
        end

        def messages(*args)
          traverse(@result.messages(*args), @path, *args) # TODO: return [] if nil
        end

        def advance(*path)
          path = @path + path.compact # remove index if nil.
          return if traverse(@result.errors, path) == {}

          Pointer.new(@result, path)
        end

      private
        def traverse(hash, path)
          path.inject(hash) { |errs, segment| errs.fetch(segment, {}) } # FIXME. test if all segments present.
        end
      end
    end
  end
end
