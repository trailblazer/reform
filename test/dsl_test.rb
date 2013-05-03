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