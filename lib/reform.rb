require 'reform/form'
require 'reform/form/composition'
require 'reform/form/active_model'

if defined?(Rails) # DISCUSS: is everyone ok with this?
  require 'reform/rails'
end