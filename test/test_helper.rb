require "reform"
require 'minitest/autorun'
require "representable/debug"
require "declarative/testing"
require "pp"

class BaseTest < MiniTest::Spec
  class AlbumForm < Reform::Form
    property :title

    property :hit do
      property :title
    end

    collection :songs do
      property :title
    end
  end

  Song   = Struct.new(:title, :length)
  Album  = Struct.new(:title, :hit, :songs, :band)
  Band   = Struct.new(:label)
  Label  = Struct.new(:name)
  Length = Struct.new(:minutes, :seconds)


  let (:hit) { Song.new("Roxanne") }
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

require "reform/form/dry"
Reform::Contract.class_eval do
  feature Reform::Form::Dry
end
# FIXME!
Reform::Form.class_eval do
  feature Reform::Form::Dry
end
