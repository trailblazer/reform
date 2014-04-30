require 'test_helper'

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

class FormCompositionTest < MiniTest::Spec
  Song      = Struct.new(:id, :title)
  Requester = Struct.new(:id, :name)

  class RequestForm < Reform::Form
    include Composition

    property  :name,          :on =>  :requester
    property  :requester_id,  :on => :requester, :as => :id
    properties [:title, :id], :on => :song
    # property  :channel # FIXME: what about the "main model"?
    property :channel, :empty => true, :on => :song

    validates :name, :title, :channel, :presence => true
  end

  let (:form)   { RequestForm.new(:song => song, :requester => requester) }
  let (:song)   { Song.new(1, "Rio") }
  let (:requester) { Requester.new(2, "Duran Duran") }


  # delegation form -> composition works
  it { form.id.must_equal 1 }
  it { form.title.must_equal "Rio" }
  it { form.name.must_equal "Duran Duran" }
  it { form.requester_id.must_equal 2 }
  it { form.channel.must_equal nil }

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
      form.validate("title" => "Greyhound", "name" => "Frenzal Rhomb", "channel" => "JJJ")

      hash = {}

      form.save do |data, map|
        hash = map
      end

      hash.must_equal({:song=>{:title=>"Greyhound", :id=>1, :channel => "JJJ"}, :requester=>{:name=>"Frenzal Rhomb", :id=>2}})
    end

    it "pushes data to models and calls #save when no block passed" do
      song.extend(Saveable)
      requester.extend(Saveable)

      form.validate("title" => "Greyhound", "name" => "Frenzal Rhomb")
      form.save

      requester.name.must_equal "Frenzal Rhomb"
      requester.saved?.must_equal true
      song.title.must_equal "Greyhound"
      song.saved?.must_equal true
    end
  end
end
