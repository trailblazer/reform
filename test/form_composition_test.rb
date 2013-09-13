require 'test_helper'

class FormCompositionTest < MiniTest::Spec
  class SongForm < Reform::Form
    include Composition

    property  :title,           :on => :song
    properties [:name, :genre], :on => :artist

    validates :name, :title, :genre, :presence => true
  end

  let (:form)   { SongForm.new(:song => song, :artist => artist) }
  let (:song)   { OpenStruct.new(:title => "Rio") }
  let (:artist) { OpenStruct.new(:name => "Duran Duran") }


  # delegation form -> composition works
  it { form.title.must_equal  "Rio" }
  it { form.name.must_equal   "Duran Duran" }
  # delegation form -> composed models (e.g. when saving this can be handy)
  it { form.song.must_equal   song }
  it { form.artist.must_equal artist }


  it "creates Composition for you" do
    form.validate("title" => "Greyhound", "name" => "Frenzal Rhomb").must_equal false
  end

  describe "#save" do
    it "provides data block argument" do
      hash = {}

      form.save do |data, map|
        hash[:name]   = data.name
        hash[:title]  = data.title
      end

      hash.must_equal({:name=>"Duran Duran", :title=>"Rio"})
    end

    it "provides nested symbolized hash as second block argument" do
      hash = {}

      form.save do |data, map|
        hash = map
      end

      hash.must_equal({:song=>{:title=>"Rio"}, :artist=>{:name=>"Duran Duran"}})
    end

    it "pushes data to models when no block passed" do
      form.validate("title" => "Greyhound", "name" => "Frenzal Rhomb")
      form.save

      artist.name.must_equal "Frenzal Rhomb"
      song.title.must_equal "Greyhound"
    end
  end
end
