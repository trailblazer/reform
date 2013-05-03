require 'test_helper'

class DslTest < MiniTest::Spec
  class SongForm < Reform::Form
    include DSL

    property :title,  :on => :song
    property :name,   :on => :artist

    validates :name, :title, presence: true
  end

  let (:form) { SongForm.new(:song => OpenStruct.new(:title => "Rio"), :artist => OpenStruct.new()) }

  it "what" do
    form.validate("title" => "Greyhound").must_equal false
  end

  describe "::properties" do
    class SuperSongForm < Reform::Form
      include DSL

      properties [:title, :year], on: :song
      property :name, on: :artist

      validates :year, :title, presence: true
    end

    let (:form) {
      SuperSongForm.new(
        :song => OpenStruct.new(:title => "Rio", :year => 1990),
        :artist => OpenStruct.new()
      )
    }

    it "works with an array of properties" do
      form.validate("title" => "Greyhound", "year" => 1990).must_equal true
    end

  end
end