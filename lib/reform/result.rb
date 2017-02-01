# form.errors => result.messages(locale: :default)
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

      # Provides the old API for Rails and friends.
      # Note that this might become an optional "deprecation" gem in Reform 3.
      class Errors
        def initialize(result, form)
          @result = result
          @form   = form

          @dotted_errors = {} # Reform does not endorse this style of error msgs.
          DottedErrors.(@form, [], @dotted_errors)
        end

        # PROTOTYPING. THIS WILL GO TO A SEPARATE GEM IN REFORM 2.4/3.0.
        DottedErrors = ->(form, prefix, hash) do
          bla=form.instance_variable_get(:@result) # FIXME.
          return unless bla
          form.instance_variable_get(:@result).errors.collect { |k,v| hash[ [*prefix, k].join(".").to_sym] = v }

          form.schema.each(twin: true) { |dfn|
            Disposable::Twin::PropertyProcessor.new(dfn, form).() do |frm, i|
              DottedErrors.(form.send(dfn[:name])[i], [*prefix, dfn[:name], i], hash) and next if i
              DottedErrors.(form.send(dfn[:name]), [*prefix, dfn[:name]], hash)
            end
          }
        end

        def messages(*args)
          # warn "[Reform] form.errors.messages will be deprecated in Reform 2.4."
          # @result.messages(*args)
          @dotted_errors
        end

        def size
          messages.size
        end
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
          traverse(@result.errors(*args), @path, *args) # TODO: return [] if nil
        end

        # def messages(*args)
        #   traverse(@result.messages(*args), @path, *args) # TODO: return [] if nil
        # end

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

    # Ensure that we can return Active Record compliant full messages when using dry
    # we only want unique messages in our array
    # human_field = field.to_s.gsub(/([\.\_])+/, " ").gsub(/(\b\w)+/) { |s| s.capitalize }
    # @full_errors.add("#{human_field} #{message}")
