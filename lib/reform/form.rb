require "trailblazer/activity/dsl/linear"
require "trailblazer/developer"
require "trailblazer/declarative"

require "delegate"

require "reform/deserialize"

# PPP: property parsing pipeline :)
module Reform
  # This class shouldn't implement/expose any runtime behavior. but then, we do define filters here :grimace:
  class Form #< Contract
    # DISCUSS: this is a pure DSL object
    extend Trailblazer::Declarative::Schema::State
    extend Trailblazer::Declarative::Schema::State::Inherited

def self.feature(mod) # FIXME: implement!
  include mod
end

    class InvalidOptionsCombinationError < StandardError; end

    def self.default_nested_class
      Form
    end

    # require "reform/form/validate"
    # include Validate # override Contract#validate with additional behaviour.

    require "reform/form/populator"

    # FIXME: move
    def [](name)
      @arbitrary_bullshit ||= {} # FIXME
      @arbitrary_bullshit[name]
    end

    # DISCUSS: should this be {form/property.rb}?
    module Property
      # Add macro logic, e.g. for :populator.
      def property(name, options={}, &block)
        parse_block   = options[:parse_block] || ->(*) {} # FIXME: use fucking kwargs everywhere!
        parse_inject  = options[:parse_inject] || [] # per {#property} we can define injection variables for the PPP.

        if (options.keys & %i[skip_if populator]).size == 2
          raise InvalidOptionsCombinationError.new(
            "[Reform] #{self}:property:#{name} Do not use skip_if and populator together, use populator with skip! instead"
          )
        end

        definition = Property.definition_for(name: name, nested_class: Reform::Form, block: block)

        # if composition and inherited we also need this setting
        # to correctly inherit modules
        options[:_inherited] = options[:inherit] if options.key?(:on) && options.key?(:inherit)

        kws = {}
        kws[:replace] = options[:replace] # FIXME

        # When {parse: false} is set, meaning we shall *not* read the property's value from the input fragment,
        # we simply use a slightly slimmer PPP which doesn't have {#key?} and {#read}.
        if options[:read] == false
          kws[:property_activity] = Deserialize::Property # normally this is {Deserialize::Property::Read}.
          kws[:set] = options.key?(:set) ? options[:set] : true # TODO: handle this with a separate {Property} class.
        end

        options[:writeable] ||= options.delete(:writable) if options.key?(:writable)

        # for virtual collection we need at least to have the collection equal to [] to
        # avoid issue when the populator
        if (options.keys & %i[collection virtual]).size == 2
          options = { default: [] }.merge(options)
        end

        # definition = super(name, options, &block) # letdisposable and declarative gems sort out inheriting of properties, and so on.


        # DISCUSS: should we update store here?
        state.update!("artifact/deserializer") do |deserializer|
          Reform::Deserialize::DSL.add_property_to_deserializer!(name, deserializer, definition: definition, parse_block: parse_block, inject: parse_inject, **kws)
        end

        definitions = state.update!("dsl/definitions") do |defs|
          defs.merge(
            name => definition
          )
        end

        require "reform/twin"
        state.update!("artifact/twin") do |twin|
          Reform::Twin.add_property_to_twin!(name, twin, definitions, **kws)
        end

=begin
        deserializer_options = definition[:deserializer]

        # Populators
        internal_populator = Populator::Sync.new(nil)
        if block = definition[:populate_if_empty]
          internal_populator = Populator::IfEmpty.new(block)
        end
        if block = definition[:populator] # populator wins over populate_if_empty when :inherit
          internal_populator = Populator.new(block)
        end
        definition.merge!(internal_populator: internal_populator) unless options[:internal_populator]
        external_populator = Populator::External.new

        # always compute a parse_pipeline for each property of the deserializer and inject it via :parse_pipeline.
        # first, letrepresentable compute the pipeline functions by invoking #parse_functions.
        if definition[:nested]
          parse_pipeline = ->(input, opts) do
            functions = opts[:binding].send(:parse_functions)
            pipeline  = Representable::Pipeline[*functions] # Pipeline[StopOnExcluded, AssignName, ReadFragment, StopOnNotFound, OverwriteOnNil, Collect[#<Representable::Function::CreateObject:0xa6148ec>, #<Representable::Function::Decorate:0xa6148b0>, Deserialize], Set]

            pipeline  = Representable::Pipeline::Insert.(pipeline, external_populator,            replace: Representable::CreateObject::Instance)
            pipeline  = Representable::Pipeline::Insert.(pipeline, Representable::Decorate,       delete: true)
            pipeline  = Representable::Pipeline::Insert.(pipeline, Deserialize,                   replace: Representable::Deserialize)
            pipeline  = Representable::Pipeline::Insert.(pipeline, Representable::SetValue,       delete: true) # FIXME: only diff to options without :populator
          end
        else
          parse_pipeline = ->(input, opts) do
            functions = opts[:binding].send(:parse_functions)
            pipeline  = Representable::Pipeline[*functions] # Pipeline[StopOnExcluded, AssignName, ReadFragment, StopOnNotFound, OverwriteOnNil, Collect[#<Representable::Function::CreateObject:0xa6148ec>, #<Representable::Function::Decorate:0xa6148b0>, Deserialize], Set]

            # FIXME: this won't work with property :name, inherit: true (where there is a populator set already).
            pipeline  = Representable::Pipeline::Insert.(pipeline, external_populator, replace: Representable::SetValue) if definition[:populator] # FIXME: only diff to options without :populator
            pipeline
          end
        end

        if proc = definition[:skip_if]
          proc = Reform::Form::Validate::Skip::AllBlank.new if proc == :all_blank
          deserializer_options.merge!(skip_parse: proc) # TODO: same with skip_parse ==> External
        end

        # per default, everything should be writeable for the deserializer (we're only writing on the form). however, allow turning it off.
        deserializer_options.merge!(writeable: true) unless deserializer_options.key?(:writeable)
=end

        definition
      end

    # GENERIC DSL
     # Schema
      Definition = Struct.new(:name, :nested)

      def self.definition_for(name:, block: nil, nested_class:, **options)
        block = Class.new(nested_class) { class_eval(&block) } if block # TODO: feature, defaults

        Definition.new(name, block).freeze
      end
    # GENERIC DSL end




      module Deserialize
        module Macro
          module_function

          def self.default(*args); return Trailblazer::Activity::Right, *args end # this step doesn't do anything!

          def Default(field_name, static_value)
            {
              task: method(:default),
              after: :read, magnetic_to: :key_not_found, Trailblazer::Activity::Railway.Output(:success) => Trailblazer::Activity::Railway.Track(:success), # DISCUSS: do we need a failure output here?
              inject: [{ value: ->(ctx, **) {static_value} }],# input: [:key],
              id: :default, field_name: :default  # we don't need {:value} here, do we?
            }
          end
        end




      end # Deserialize
    end # Deserialize


    # @Runtime
    # Override {Railway#call} and always use the top-most {:exec_context},
    # which is the currently validated form.
    module Call
      def call(*args, exec_context:, **kws)
        @activity.(*args, **kws.merge(exec_context: exec_context))
      end
    end

    extend Property



    # require "disposable/twin/changed"
    # feature Disposable::Twin::Changed

    # require "disposable/twin/sync"
    # feature Disposable::Twin::Sync
    # feature Disposable::Twin::Sync::SkipGetter

    # require "disposable/twin/save"
    # feature Disposable::Twin::Save

    def skip!
      Representable::Pipeline::Stop
    end

    # require "reform/form/call" # FIXME: remove
    include Call

# TODO: this should be at the top of class body at some point :)
    def self.initial_deserializer_activity
      Class.new(Trailblazer::Activity::Railway) do
        extend(Reform::Form::Call)
      end
    end

    initialize_state!(
      "artifact/hydrate" =>       [Class.new(Trailblazer::Activity::Railway), {copy: Trailblazer::Declarative::State.method(:subclass)}],
      "artifact/deserializer" =>  [initial_deserializer_activity, {copy: Trailblazer::Declarative::State.method(:subclass)}],
      "artifact/twin" => [Hash.new, {}], # copy # FIXME: we need real definitions here, I guess.
      "dsl/definitions" => [Hash.new, {}] # copy # FIXME: we need real definitions here, I guess.
    )

    require "reform/form/dsl/validation"
    require "reform/validation/groups"
    extend DSL::Validation # Form.validation do .. end

  end
end
    require "reform/form/validate"

require "reform/form/sync"


