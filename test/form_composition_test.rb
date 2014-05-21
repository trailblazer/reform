require 'test_helper'

class FormCompositionTest < MiniTest::Spec
  Song      = Struct.new(:id, :title)
  Requester = Struct.new(:id, :name, :requester)

  class RequestForm < Reform::Form
    include Composition

    # TODO: remove skip_accessors in 1.1.
    property  :name,          :on =>  :requester, :skip_accessors => true
    property  :requester_id,  :on => :requester, :as => :id, :skip_accessors => true
    properties [:title, :id], :on => :song
    # property  :channel # FIXME: what about the "main model"?
    property :channel, :empty => true, :on => :song
    property :requester,      :on => :requester, :skip_accessors => true

    validates :name, :title, :channel, :presence => true
  end

  let (:form)   { RequestForm.new(:song => song, :requester => requester) }
  let (:song)   { Song.new(1, "Rio") }
  let (:requester) { Requester.new(2, "Duran Duran", "MCP") }


  # delegation form -> composition works
  it { form.id.must_equal 1 }
  it { form.title.must_equal "Rio" }
  it { form.name.must_equal "Duran Duran" }
  it { form.requester_id.must_equal 2 }
  it { form.channel.must_equal nil }
  it { form.requester.must_equal "MCP" } # same name as composed model.

  # [DEPRECATED] # TODO: remove in 1.2.
  # delegation form -> composed models (e.g. when saving this can be handy)
  it { form.song.must_equal      song }


  # #model just returns <Composition>.
  it { form.model.must_be_kind_of Reform::Composition }

  # #model[] -> composed models
  it { form.model[:requester].must_equal requester }
  it { form.model[:song].must_equal      song }


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

      hash.must_equal({:song=>{:title=>"Greyhound", :id=>1, :channel => "JJJ"}, :requester=>{:name=>"Frenzal Rhomb", :id=>2, :requester => "MCP"}})
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
