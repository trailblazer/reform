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
  def self.included(base)
    base.extend ClassMethods
    base.extend Included
  end

  module Included # TODO: use representable's inheritance mechanism.
    def included(base)
      @property_configs.each { |cfg| base.property(*cfg.first, &cfg.last) }
    end
  end

  module ClassMethods
    def property(*args, &block)
      property_configs << [args, block]
    end

    def property_configs
      @property_configs ||= []
    end
  end
end


class ModuleInclusionTest < MiniTest::Spec
  module BandPropertyForm
    include Reform::Form::Module

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