module Reform::Validation
  # A Group is a set of native validations, targeting a validation backend (AM, Lotus, Dry).
  # Group receives configuration via #validates and #validate and translates that to its
  # internal backend.
  #
  # The #call method will run those validations on the provided objects.

  # Set of Validation::Group objects.
  # This implements adding, iterating, and finding groups, including "inheritance" and insertions.
  class Groups < Array
    def initialize(group_class)
      @group_class = group_class
    end

    def add(name, options)
      if options[:inherit]
        return self[name] if self[name]
      end

      i = index_for(options)

      self.insert(i, [name, group = @group_class.new(options), options]) # Group.new
      group
    end

    private

    def index_for(options)
      return find_index { |el| el.first == options[:after] } + 1 if options[:after]
      size # default index: append.
    end

    def [](name)
      cfg = find { |c| c.first == name }
      return unless cfg
      cfg[1]
    end

    # Runs all validations groups according to their rules and returns all Result objects.
    class Validate
      def self.call(groups, form)
        results = {}

        groups.collect do |(name, group, options)|
          next unless evaluate?(options[:if], results, form)

          results[name] = group.(form) # run validation for group. store and collect <Result>.
        end
      end

      def self.evaluate?(depends_on, results, form)
        return true if depends_on.nil?
        return !results[depends_on].nil? && results[depends_on].success? if depends_on.is_a?(Symbol)
        form.instance_exec(results, &depends_on)
      end
    end
  end
end
