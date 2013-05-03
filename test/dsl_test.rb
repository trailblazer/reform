require 'test_helper'

class DslTest < MiniTest::Spec
  class SongForm < Reform::Form
    include DSL

    property  :title,  :on => :song
    properties [:name, :genre],   :on => :artist

    validates :name, :title, :genre, presence: true
  end

  let (:form) { SongForm.new(:song => OpenStruct.new(:title => "Rio"), :artist => OpenStruct.new()) }

  it "works by creating Representer and Composition for you" do
    form.validate("title" => "Greyhound", "name" => "Frenzal Rhomb").must_equal false
  end
end

require 'reform/form/active_model'
class ActiveModelTest < MiniTest::Spec
   class SongForm < Reform::Form
    include DSL
    include Reform::Form::ActiveModel

    property  :title,  :on => :song
    properties [:name, :genre],   :on => :artist
  end

  let (:rio) { OpenStruct.new(:title => "Rio") }
  let (:form) { SongForm.new(:song => OpenStruct.new(:title => "Rio"), :artist => OpenStruct.new()) }

  it "creates model readers" do
    form.song.must_equal rio
  end
end