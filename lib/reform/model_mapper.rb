require 'representable/hash'
# TODO: rename to Mapper?
# maps model(s) to form and back.
class Reform::ModelMapper
  include Representable::Hash

  def initialize(models)
    models.each do |name, obj|
      instance_variable_set(:"@#{name}", obj)
    end
  end

  module Property
    def property(name, options)
      delegate name, "#{name}=", to: "@#{options[:on]}"
      super
    end
  end
  extend Property

  # Move key-value tuples under the key having the respective object's name.
  def to_nested_hash
    {}.tap do |hsh|
      to_hash.each do |name, val|
        obj = model_for_property(name)
        hsh[obj] ||= {}
        hsh[obj][name] = val
      end
    end
  end

  # TODO: remove this to an optional layer since we don't want this everywhere (e.g. when using services).
  def save(*args)
    from_hash(*args)
  end

private
  def model_for_property(name)
    # FIXME: to be removed pretty soon.
    representable_attrs.each do |cfg|
      return cfg.options[:on] if cfg.name == name
    end
  end
end