require "test_helper"

class ReformTest < Minitest::Spec
  let(:comp) { OpenStruct.new(name: "Duran Duran", title: "Rio") }

  let(:form) { SongForm.new(comp) }

  class SongForm < TestForm
    property :name
    property :title

    validation do
      required(:name).filled
    end
  end

  describe "(new) form with empty models" do
    let(:comp) { OpenStruct.new }

    it "returns empty fields" do
      assert_nil form.title
      _(form.name).must_be_nil
    end

    describe "and submitted values" do
      it "returns filled-out fields" do
        form.validate("name" => "Duran Duran")

        assert_nil form.title
        _(form.name).must_equal "Duran Duran"
      end
    end
  end

  describe "(edit) form with existing models" do
    it "returns filled-out fields" do
      _(form.name).must_equal  "Duran Duran"
      _(form.title).must_equal "Rio"
    end
  end

  describe "#validate" do
    let(:comp) { OpenStruct.new }

    it "ignores unmapped fields in input" do
      form.validate("name" => "Duran Duran", :genre => "80s")
      assert_raises NoMethodError do
        form.genre
      end
    end

    it "returns true when valid" do
      _(form.validate("name" => "Duran Duran")).must_equal true
    end

    it "exposes input via property accessors" do
      form.validate("name" => "Duran Duran")

      _(form.name).must_equal "Duran Duran"
    end

    it "doesn't change model properties" do
      form.validate("name" => "Duran Duran")

      assert_nil comp.name # don't touch model, yet.
    end

    # TODO: test errors. test valid.
    describe "invalid input" do
      class ValidatingForm < TestForm
        property :name
        property :title

        validation do
          required(:name).filled
          required(:title).filled
        end
      end
      let(:form) { ValidatingForm.new(comp) }

      it "returns false when invalid" do
        _(form.validate({})).must_equal false
      end

      it "populates errors" do
        form.validate({})
        _(form.errors.messages).must_equal({name: ["must be filled"], title: ["must be filled"]})
      end
    end
  end

  describe "#save" do
    let(:comp) { OpenStruct.new }
    let(:form) { SongForm.new(comp) }

    before { form.validate("name" => "Diesel Boy") }

    it "xxpushes data to models" do
      form.save

      _(comp.name).must_equal "Diesel Boy"
      assert_nil comp.title
    end

    describe "#save with block" do
      it do
        hash = {}

        form.save do |map|
          hash = map
        end

        _(hash).must_equal({"name" => "Diesel Boy", "title" => nil})
      end
    end
  end

  describe "#model" do
    it { _(form.model).must_equal comp }
  end

  describe "inheritance" do
    class HitForm < SongForm
      property :position
      validation do
        required(:position).filled
      end
    end

    let(:form) { HitForm.new(OpenStruct.new()) }
    it do
      form.validate({"title" => "The Body"})
      _(form.title).must_equal "The Body"
      assert_nil form.position
      _(form.errors.messages).must_equal({name: ["must be filled"], position: ["must be filled"]})
    end
  end
end

class OverridingAccessorsTest < BaseTest
  class SongForm < TestForm
    property :title

    def title=(v) # used in #validate.
      super v * 2
    end

    def title # used in #sync.
      super.downcase
    end
  end

  let(:song) { Song.new("Pray") }
  subject { SongForm.new(song) }

  # override reader for presentation.
  it { _(subject.title).must_equal "pray" }

  describe "#save" do
    before { subject.validate("title" => "Hey Little World") }

    # reader always used
    it { _(subject.title).must_equal "hey little worldhey little world" }

    # the reader is not used when saving/syncing.
    it do
      subject.save do |hash|
        _(hash["title"]).must_equal "Hey Little WorldHey Little World"
      end
    end

    # no reader or writer used when saving/syncing.
    it do
      song.extend(Saveable)
      subject.save
      _(song.title).must_equal "Hey Little WorldHey Little World"
    end
  end
end

class MethodInFormTest < MiniTest::Spec
  class AlbumForm < TestForm
    property :title

    def title
      "The Suffer And The Witness"
    end

    property :hit do
      property :title

      def title
        "Drones"
      end
    end
  end

  # methods can be used instead of created accessors.
  subject { AlbumForm.new(OpenStruct.new(hit: OpenStruct.new)) }
  it { _(subject.title).must_equal "The Suffer And The Witness" }
  it { _(subject.hit.title).must_equal "Drones" }
end
