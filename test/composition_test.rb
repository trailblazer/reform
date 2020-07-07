require "test_helper"

class FormCompositionInheritanceTest < MiniTest::Spec
  module SizePrice
    include Reform::Form::Module

    property :price
    property :size

    module InstanceMethods
      def price(for_size: size)
        case for_size.to_sym
          when :s then super() * 1
          when :m then super() * 2
          when :l then super() * 3
        end
      end
    end
  end

  class OutfitForm < TestForm
    include Reform::Form::Composition
    include SizePrice

    property :price,  inherit: true, on: :tshirt
    property :size,   inherit: true, on: :measurement
  end

  let(:measurement) { Measurement.new(:l) }
  let(:tshirt)      { Tshirt.new(2, :m) }
  let(:form)        { OutfitForm.new(tshirt: tshirt, measurement: measurement) }

  Tshirt = Struct.new(:price, :size)
  Measurement = Struct.new(:size)

  it { assert_equal form.price, 6 }
  it { assert_equal form.price(for_size: :s), 2 }
end

class FormCompositionTest < MiniTest::Spec
  Song      = Struct.new(:id, :title, :band)
  Requester = Struct.new(:id, :name, :requester)
  Band      = Struct.new(:title)

  class RequestForm < TestForm
    include Composition

    property  :name,          on: :requester
    property  :requester_id,  on: :requester, from: :id
    properties :title, :id, on: :song
    # property  :channel # FIXME: what about the "main model"?
    property :channel, virtual: true, on: :song
    property :requester,      on: :requester
    property :captcha,        on: :song, virtual: true

    validation do
      params do
        required(:name).filled
        required(:title).filled
      end
    end

    property :band, on: :song do
      property :title
    end
  end

  let(:form)       { RequestForm.new(song: song, requester: requester) }
  let(:song)       { Song.new(1, "Rio", band) }
  let(:requester)  { Requester.new(2, "Duran Duran", "MCP") }
  let(:band)       { Band.new("Duran^2") }

  # delegation form -> composition works
  it { assert_equal form.id, 1 }
  it { assert_equal form.title, "Rio" }
  it { assert_equal form.name, "Duran Duran" }
  it { assert_equal form.requester_id, 2 }
  it { assert_nil form.channel }
  it { assert_equal form.requester, "MCP" } # same name as composed model.
  it { assert_nil form.captcha }

  # #model just returns <Composition>.
  it { assert form.mapper.is_a? Disposable::Composition }

  # #model[] -> composed models
  it { assert_equal form.model[:requester], requester }
  it { assert_equal form.model[:song], song }

  it "creates Composition for you" do
    assert_equal form.validate("title" => "Greyhound", "name" => "Frenzal Rhomb"), true
    assert_equal form.validate("title" => "", "name" => "Frenzal Rhomb"), false
  end

  describe "#save" do
    # #save with {}
    it do
      hash = {}

      form.save do |map|
        hash[:name]   = form.name
        hash[:title]  = form.title
      end

      assert_equal hash, name: "Duran Duran", title: "Rio"
    end

    it "provides nested symbolized hash as second block argument" do
      form.validate("title" => "Greyhound", "name" => "Frenzal Rhomb", "channel" => "JJJ", "captcha" => "wonderful")

      hash = nil

      form.save do |map|
        hash = map
      end

      assert_equal hash, {
        song: {"title" => "Greyhound", "id" => 1, "channel" => "JJJ", "captcha" => "wonderful", "band" => {"title" => "Duran^2"}},
        requester: {"name" => "Frenzal Rhomb", "id" => 2, "requester" => "MCP"}
      }
    end

    it "xxx pushes data to models and calls #save when no block passed" do
      song.extend(Saveable)
      requester.extend(Saveable)
      band.extend(Saveable)

      form.validate("title" => "Greyhound", "name" => "Frenzal Rhomb", "captcha" => "1337")
      assert_equal form.captcha, "1337" # TODO: move to separate test.

      form.save

      assert_equal requester.name, "Frenzal Rhomb"
      assert_equal requester.saved?, true
      assert_equal song.title, "Greyhound"
      assert_equal song.saved?, true
      assert_equal song.band.title, "Duran^2"
      assert_equal song.band.saved?, true
    end

    it "returns true when models all save successfully" do
      song.extend(Saveable)
      requester.extend(Saveable)
      band.extend(Saveable)

      assert_equal form.save, true
    end

    it "returns false when one or more models don't save successfully" do
      module Unsaveable
        def save
          false
        end
      end

      song.extend(Unsaveable)
      requester.extend(Saveable)
      band.extend(Saveable)

      assert_equal form.save, false
    end
  end
end

class FormCompositionCollectionTest < MiniTest::Spec
  Book = Struct.new(:id, :name)
  Library = Struct.new(:id) do
    def books
      [Book.new(1, "My book")]
    end
  end

  class LibraryForm < TestForm
    include Reform::Form::Composition

    collection :books, on: :library do
      property :id
      property :name
    end
  end

  let(:form)   { LibraryForm.new(library: library) }
  let(:library) { Library.new(2) }

  it { form.save { |hash| assert_equal hash, { library: { "books" => [{ "id" => 1, "name" => "My book" }] } } } }
end
