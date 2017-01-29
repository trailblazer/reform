class Reform::Contract::Errors
  def initialize(result=nil)
    @result = result
    @errors = {}
    @full_errors = Set.new
  end

  module Merge
    def merge!(errors, prefix)
      errors.messages.each do |field, msgs|
        unless field.to_sym == :base
          field = [prefix,field].compact.join(".").to_sym # TODO: why is that a symbol in Rails?
        end

        msgs.each do |msg|
          next if messages[field] and messages[field].include?(msg)
          add(field, msg)
        end
      end
    end

    def to_s
      messages.inspect
    end
  end
  include Merge

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

  def size
    @errors.values.flatten.size
  end
  alias :count :size

  # TODO: deprecate empty?
  def empty?
    size.zero?
  end

  def success?
    empty?
  end
end
