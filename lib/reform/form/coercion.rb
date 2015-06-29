require "disposable/twin/coercion"

Reform::Form.class_eval do
  Coercion = Disposable::Twin::Coercion
end