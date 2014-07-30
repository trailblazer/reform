require 'test_helper'
require 'representable/json'

class InheritTest < BaseTest
  class CompilationForm < AlbumForm

    property :hit, :inherit => true do
      property :rating
      validates :title, :rating, :presence => true
    end

    # puts representer_class.representable_attrs.
    #   get(:hit)[:extend].evaluate(nil).new(OpenStruct.new).rating
  end

  let (:album) { Album.new(nil, OpenStruct.new(:hit => OpenStruct.new()) ) }
  subject { CompilationForm.new(album) }


  # valid.
  it {
    subject.validate("hit" => {"title" => "LA Drone", "rating" => 10})
    subject.hit.title.must_equal "LA Drone"
    subject.hit.rating.must_equal 10
    subject.errors.messages.must_equal({})
  }

  it do
    subject.validate({})
    subject.hit.title.must_equal nil
    subject.hit.rating.must_equal nil
    subject.errors.messages.must_equal({:"hit.title"=>["can't be blank"], :"hit.rating"=>["can't be blank"]})
  end
end

module Reform::Form::Module
  extend Forwardable

    # extend Uber::InheritableAttr
    # # representer_class gets inherited (cloned) to subclasses.
    # inheritable_attr :representer_class
    # self.representer_class = Reform::Representer.for(:form_class => self) # only happens in Contract/Form.
    # # this should be the only mechanism to inherit, features should be stored in this as well.


    # # each contract keeps track of its features and passes them onto its local representer_class.
    # # gets inherited, features get automatically included into inline representer.
    # # TODO: the representer class should handle that, e.g. in options (deep-clone when inheriting.)
    # inheritable_attr :features
    # self.features = {}




    RESERVED_METHODS = [:model, :aliased_model, :fields, :mapper] # TODO: refactor that so we don't need that.


    module PropertyMethods
      def features
      {}
    end

      # def representer_class
      #   self
      # end


      def build_config
      Representable::Config.new(Reform::Representer::Definition)
    end


      def property(name, options={}, &block)
        options[:private_name] = options.delete(:as)

        options[:coercion_type] = options.delete(:type)

        options[:features] ||= []
        options[:features] += features.keys if block_given?

        definition = super(name, options, &block)
        setup_form_definition(definition) if block_given? or options[:form]

        create_accessor(name)
        definition
      end

      def collection(name, options={}, &block)
        options[:collection] = true

        property(name, options, &block)
      end

      def properties(names, *args)
        names.each { |name| property(name, *args) }
      end

      def setup_form_definition(definition)
        options = {
          # TODO: make this a bit nicer. why do we need :form at all?
          :form         => definition[:extend] || definition[:form], # :form is always just a Form class name.
          :pass_options => true, # new style of passing args
          :prepare      => lambda { |form, args| form }, # always just return the form without decorating.
          :representable => true, # form: Class must be treated as a typed property.
        }

        definition.merge!(options)
      end

    private
      def create_accessor(name)
        handle_reserved_names(name)

        # Make a module that contains these very accessors, then include it
        # so they can be overridden but still are callable with super.
        accessors = Module.new do
          extend Forwardable
          delegate [name, "#{name}="] => :fields
        end
        include accessors
      end

      def handle_reserved_names(name)
        raise "[Reform] the property name '#{name}' is reserved, please consider something else using :as." if RESERVED_METHODS.include?(name)
      end
    end

    def self.included(base)
      base.send :include, Representable

      base.extend PropertyMethods
    end
end


class ModuleInclusionTest < MiniTest::Spec
  module BandPropertyForm
    include Reform::Form::Module
    register_feature Reform::Form::Module

    property :band do
      property :title
    end
  end


  class SongForm < Reform::Form
    property :title

    include BandPropertyForm
  end


  it { SongForm.new(OpenStruct.new(:band => OpenStruct.new(:title => "Time Again"))).band.title.must_equal "Time Again" }
end