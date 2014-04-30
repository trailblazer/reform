require 'test_helper'

class FormCompositionTest < MiniTest::Spec
  Song      = Struct.new(:id, :title)
  Requester = Struct.new(:id, :name)

  class RequestForm < Reform::Form
    include Composition

    property  :name,          :on =>  :requester
    property  :requester_id,  :on => :requester, :as => :id
    properties [:title, :id], :on => :song
    # property  :channel # FIXME: what about the "main model"?

    validates :name, :title, :presence => true
  end

  let (:form)   { RequestForm.new(:song => song, :requester => requester) }
  let (:song)   { Song.new(1, "Rio") }
  let (:requester) { Requester.new(2, "Duran Duran") }


  # delegation form -> composition works
  it { form.id.must_equal 1 }
  it { form.title.must_equal "Rio" }
  it { form.name.must_equal "Duran Duran" }
  it { form.requester_id.must_equal 2 }

  # delegation form -> composed models (e.g. when saving this can be handy)
  it { form.song.must_equal   song }
  it { form.requester.must_equal requester }


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

      hash.must_equal({:song=>{:title=>"Rio", :id=>1}, :requester=>{:name=>"Duran Duran", :id=>2}})
    end

    it "pushes data to models when no block passed" do
      form.validate("title" => "Greyhound", "name" => "Frenzal Rhomb")
      form.save

      requester.name.must_equal "Frenzal Rhomb"
      song.title.must_equal "Greyhound"
    end
  end
end
