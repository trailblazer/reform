require 'test_helper'

class FormCompositionTest < MiniTest::Spec
  Song      = Struct.new(:id, :title, :band)
  Requester = Struct.new(:id, :name, :requester)
  Band      = Struct.new(:title)

  class RequestForm < Reform::Form
    include Composition

    property  :name,          :on =>  :requester
    property  :requester_id,  :on => :requester, :as => :id
    properties [:title, :id], :on => :song
    # property  :channel # FIXME: what about the "main model"?
    property :channel, :empty => true, :on => :song
    property :requester,      :on => :requester
    property :captcha,        :on => :song, :empty => true

    validates :name, :title, :channel, :presence => true

    property :band,           :on => :song do
      property :title
    end
  end

  let (:form)   { RequestForm.new(:song => song, :requester => requester) }
  let (:song)   { Song.new(1, "Rio", Band.new("Duran^2")) }
  let (:requester) { Requester.new(2, "Duran Duran", "MCP") }


  # delegation form -> composition works
  it { form.id.must_equal 1 }
  it { form.title.must_equal "Rio" }
  it { form.name.must_equal "Duran Duran" }
  it { form.requester_id.must_equal 2 }
  it { form.channel.must_equal nil }
  it { form.requester.must_equal "MCP" } # same name as composed model.
  it { form.captcha.must_equal nil }

  # #model just returns <Composition>.
  it { form.model.must_be_kind_of Reform::Composition }

  # #model[] -> composed models
  it { form.model[:requester].must_equal requester }
  it { form.model[:song].must_equal      song }


  it "creates Composition for you" do
    form.validate("title" => "Greyhound", "name" => "Frenzal Rhomb").must_equal false
  end

  describe "#save" do
    # #save with {}
    it("xxx") do
      hash = {}

      form.save do |map|
        hash[:name]   = form.name
        hash[:title]  = form.title
      end

      hash.must_equal({:name=>"Duran Duran", :title=>"Rio"})
    end

    it "provides nested symbolized hash as second block argument" do
      form.validate("title" => "Greyhound", "name" => "Frenzal Rhomb", "channel" => "JJJ", "captcha" => "wonderful")

      hash = nil

      form.save do |map|
        hash = map
      end

      hash.must_equal({
        :song=>{:title=>"Greyhound", :id=>1, :channel => "JJJ", :captcha=>"wonderful"},
        :requester=>{:name=>"Frenzal Rhomb", :id=>2, :requester => "MCP"}}
      )
    end

    it "pushes data to models and calls #save when no block passed" do
      song.extend(Saveable)
      requester.extend(Saveable)

      form.validate("title" => "Greyhound", "name" => "Frenzal Rhomb", "captcha" => "1337")
      form.captcha.must_equal "1337" # TODO: move to separate test.

      form.save

      requester.name.must_equal "Frenzal Rhomb"
      requester.saved?.must_equal true
      song.title.must_equal "Greyhound"
      song.saved?.must_equal true
    end
  end
end


class FormCompositionCollectionTest < MiniTest::Spec
  Book = Struct.new(:id, :name)
  Library = Struct.new(:id) do
    def books
      [Book.new(1,"My book")]
    end
  end

  class LibraryForm < Reform::Form
    include Reform::Form::Composition

    collection :books, on: :library do
      property :id
      property :name
    end
  end

  let (:form)   { LibraryForm.new(library: library) }
  let (:library) { Library.new(2) }

  it { form.save do |hash| hash.must_equal({"books"=>[{"id"=>1, "name"=>"My book"}]}) end }
end
