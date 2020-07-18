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
  include Dry.Types()
end

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
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  module Saveable
    def save
      @saved = true
    end

    def saved?
      @saved
    end
  end
end
