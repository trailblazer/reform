module Reform
  def self.rails3_0?
    ::ActiveModel::VERSION::MAJOR == 3 and ::ActiveModel::VERSION::MINOR == 0
  end
end

require "reform/contract"
require "reform/form"
require "reform/form/composition"
require "reform/form/active_model"
require "reform/form/module"


if defined?(Rails)
  require "reform/rails"
end
