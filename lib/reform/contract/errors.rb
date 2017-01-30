class Reform::Contract::Errors
  def initialize(original_result=nil)
    @original_result = original_result
    @errors = {}
    @full_errors = Set.new
  end

  # Merge always adds errors on the same level with target, but adds prefix.
  module Merge
    def self.call(target, to_merge, prefix)
      to_merge = to_merge.find_all { |k,v| v.is_a?(Array) }.to_h # FIXME. can't we distinguish between nested in another way?

      to_merge.each do |field, msgs|
        field = prefixed(field, prefix) unless field.to_sym == :base # DISCUSS: isn't that AMV specific?

        msgs.each { |msg| target.add(field, msg) }
      end
    end

  private
    def self.prefixed(field, prefix)
      [*prefix, field].compact.join(".").to_sym # TODO: why is that a symbol in Rails?
    end
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
