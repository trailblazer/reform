require "reform"
require "minitest/autorun"
require "representable/debug"
require "declarative/testing"
require "pp"
require "pry-byebug"

require "reform/form/dry"

# setup test classes so we can test without dry being included
class TestForm < Reform::Form
  feature Reform::Form::Dry
end

class TestContract < Reform::Contract
  feature Reform::Form::Dry
end

module Types
  DRY_MODULE = Gem::Version.new(Dry::Types::VERSION) < Gem::Version.new("0.15.0") ? Dry::Types.module : Dry.Types()
  include DRY_MODULE
end

DRY_TYPES_VERSION = Gem::Version.new(Dry::Types::VERSION)
DRY_TYPES_CONSTANT = DRY_TYPES_VERSION < Gem::Version.new("0.13.0") ? Types::Form : Types::Params
DRY_TYPES_INT_CONSTANT = DRY_TYPES_VERSION < Gem::Version.new("0.13.0") ? Types::Form::Int : Types::Params::Integer

class BaseTest < MiniTest::Spec
  class AlbumForm < TestForm
    property :title

    property :hit do
      property :title
    end

    collection :songs do
      property :title
    end
  end

  Song   = Struct.new(:title, :length, :rating)
  Album  = Struct.new(:title, :hit, :songs, :band)
  Band   = Struct.new(:label)
  Label  = Struct.new(:name)
  Length = Struct.new(:minutes, :seconds)

  let(:hit) { Song.new("Roxanne") }
end

MiniTest::Spec.class_eval do
  module Saveable
    def save
      @saved = true
    end

    def saved?
      @saved
    end
  end
end
