class Reform::Contract::Errors
  def initialize(original_result=nil)
    @original_result = original_result
    @errors = {}
    @full_errors = Set.new
  end

  # Merge always adds errors on the same level with target, but adds prefix.
  module Merge
    def merge!(errors, prefix)
      errors.messages.each do |field, msgs|
        field = prefixed(field, prefix) unless field.to_sym == :base # DISCUSS: isn't that AMV specific?

        msgs.each do |msg|
          next if messages[field] and messages[field].include?(msg) # DISCUSS: why would this ever happen?
          # this is total nonsense: :"songs.title"=>["must be filled", "must be filled"],
          # why would two different forms merge their errors into one field?

          add(field, msg)
        end
      end
    end

  private
    def prefixed(field, prefix)
      [prefix,field].compact.join(".").to_sym # TODO: why is that a symbol in Rails?
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
  alias :count :size # TODO: deprecate count and size. rather introduce #to_a or #to_h.

  # TODO: deprecate empty?
  def empty?
    size.zero?
  end

  def success?
    empty?
  end
end
