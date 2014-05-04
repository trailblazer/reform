module Reform
  autoload :Contract, 'reform/contract'

  def self.rails3_0?
    ::ActiveModel::VERSION::MAJOR == 3 and ::ActiveModel::VERSION::MINOR == 0
  end
end

require 'reform/form'
require 'reform/form/composition'
require 'reform/form/active_model'

if defined?(Rails) # DISCUSS: is everyone ok with this?
  require 'reform/rails'
end
