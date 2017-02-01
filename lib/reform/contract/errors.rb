# form.errors => result.messages(locale: :default)
module Reform
  class Contract < Disposable::Twin

    # Collects all results of a form of all groups.
    class Result
      def initialize(results, nested_results)
        @results = results
        @failure = (results + nested_results).find(&:failure?)
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

      # Note: this class might be redundant in Reform 3, where the public API
      # allows/enforces to pass options to #errors (e.g. errors(locale: "br"))
      # which means we don't have to "lazy-handle" that with "pointers".
      # :private:
      class Pointer
        def initialize(result, path)
          @result, @path = result, path
        end

        def success?
          @result.success?
        end

        def errors(*args)
          traverse(@path, *args) # TODO: return [] if nil
        end

        def advance(*path)
          path = @path + path.compact # remove index if nil.
          return if traverse(path) == {}

          Pointer.new(@result, path)
        end

      private
        def traverse(path, *args)
          path.inject(@result.errors(*args)) { |errs, segment| errs.fetch(segment, {}) } # FIXME. test if all segments present.
        end
      end
    end
  end
end

class Reform::Contract::Errors
  def initialize(original_result=nil)
    @original_result = original_result
    @errors = {}
    @full_errors = Set.new
  end

  def add(field, message)
    @errors[field] ||= []
    @errors[field] << message

    # Ensure that we can return Active Record compliant full messages when using dry
    # we only want unique messages in our array
    human_field = field.to_s.gsub(/([\.\_])+/, " ").gsub(/(\b\w)+/) { |s| s.capitalize }
    @full_errors.add("#{human_field} #{message}")
  end

  def messages
    @errors
  end

  def full_messages
    @full_errors.to_a
  end

  # needed by Rails form builder.
  def [](name)
    @errors[name] || []
  end

  def success?
    size.zero?
  end

private
  def size
    @errors.values.flatten.size
  end
end
