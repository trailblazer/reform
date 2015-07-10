# The Errors class is planned to replace AM::Errors. It provides proper nested error messages.
class Reform::Contract::Errors < ActiveModel::Errors
  def merge!(errors, prefix)
    errors.messages.each do |field, msgs|
      unless field.to_sym == :base
        field = (prefix+[field]).join(".").to_sym # TODO: why is that a symbol in Rails?
      end

      msgs.each do |msg|
        next if messages[field] and messages[field].include?(msg)
        add(field, msg)
      end # Forms now contains a plain errors hash. the errors for each item are still available in item.errors.
    end
  end

  def valid? # TODO: test me in unit test.
    empty?
  end

  def to_s
    messages.inspect
  end
end # Errors
