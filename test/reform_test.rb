require 'test_helper'

class RepresenterTest < MiniTest::Spec
  class SongRepresenter < Reform::Representer
    properties [:title, :year]
  end

  let (:rpr) { SongRepresenter.new(OpenStruct.new(:title => "Disconnect, Disconnect", :year => 1990)) }

  # TODO: introduce representer_for helper.
  describe "::properties" do
    it "accepts array of property names" do
      rpr.to_hash.must_equal({"title"=>"Disconnect, Disconnect", "year" => 1990} )
    end
  end

  describe "#fields" do
    it "returns all properties as strings" do
      rpr.fields.must_equal(["title", "year"])
    end
  end
end

class FieldsTest < MiniTest::Spec
  describe "#new" do
    it "accepts list of properties" do
      fields = Reform::Fields.new([:name, :title])
      fields.name.must_equal  nil
      fields.title.must_equal nil
    end

    it "accepts list of properties and values" do
      fields = Reform::Fields.new(["name", "title"], "title" => "The Body")
      fields.name.must_equal  nil
      fields.title.must_equal "The Body"
    end

    it "processes value syms" do
      fields = Reform::Fields.new(["name", "title"], :title => "The Body")
      fields.name.must_equal  nil
      fields.title.must_equal "The Body"
    end
  end
end

class ReformTest < MiniTest::Spec
  let (:duran)  { OpenStruct.new(:name => "Duran Duran") }
  let (:rio)    { OpenStruct.new(:title => "Rio") }

  let (:form) { SongForm.new(SongAndArtistMap, comp) }

  class SongAndArtistMap < Reform::Representer
    property :name, on: :artist
    property :title, on: :song
  end

  class SongForm < Reform::Form
  end

  describe "Composition" do
    class SongAndArtist < Reform::Composition
      map({:artist => [:name], :song => [:title]}) #SongAndArtistMap.representable_attrs
    end

    let (:comp) { SongAndArtist.new(:artist => @artist=OpenStruct.new, :song => rio) }

    it "delegates to models as defined" do
      comp.name.must_equal nil
      comp.title.must_equal "Rio"
    end

    it "raises when non-mapped property" do
      assert_raises NoMethodError do
        comp.raise_an_exception
      end
    end

    it "creates readers to models" do
      comp.song.object_id.must_equal rio.object_id
      comp.artist.object_id.must_equal @artist.object_id
    end

    describe "::map_from" do
      it "creates the same mapping" do
        comp =
        Class.new(Reform::Composition) do
          map_from SongAndArtistMap
        end.
        new(:artist => duran, :song => rio)

        comp.name.must_equal "Duran Duran"
        comp.title.must_equal "Rio"
      end
    end

    describe "#nested_hash_for" do
      it "returns nested hash" do
        comp.nested_hash_for(:name => "Jimi Hendrix", :title => "Fire").must_equal({:artist=>{:name=>"Jimi Hendrix"}, :song=>{:title=>"Fire"}})
      end

      it "works with strings" do
        comp.nested_hash_for("name" => "Jimi Hendrix", "title" => "Fire").must_equal({:artist=>{:name=>"Jimi Hendrix"}, :song=>{:title=>"Fire"}})
      end

      it "works with strings in map" do
        Class.new(Reform::Composition) do
          map(:artist => ["name"])
        end.new([nil]).nested_hash_for(:name => "Jimi Hendrix").must_equal({:artist=>{:name=>"Jimi Hendrix"}})
      end
    end
  end

  describe "(new) form with empty models" do
    let (:comp) { SongAndArtist.new(:artist => OpenStruct.new, :song => OpenStruct.new) }

    it "returns empty fields" do
      form.title.must_equal nil
      form.name.must_equal  nil
    end

    describe "and submitted values" do
      it "returns filled-out fields" do
        form.validate("name" => "Duran Duran")

        form.title.must_equal nil
        form.name.must_equal  "Duran Duran"
      end
    end
  end

  describe "(edit) form with existing models" do
    let (:comp) { SongAndArtist.new(:artist => duran, :song => rio) }

    it "returns filled-out fields" do
      form.name.must_equal  "Duran Duran"
      form.title.must_equal "Rio"
    end
  end

  describe "#validate" do
    let (:comp) { SongAndArtist.new(:artist => OpenStruct.new, :song => OpenStruct.new) }

    it "ignores unmapped fields in input" do
      form.validate("name" => "Duran Duran", :genre => "80s")
      assert_raises NoMethodError do
        form.genre
      end
    end

    it "returns true when valid" do
      form.validate("name" => "Duran Duran").must_equal true
    end

    # TODO: test errors. test valid.
    it "returns false when invalid" do
      class ValidatingForm < Reform::Form
        validates :name, :presence => true
      end

      ValidatingForm.new(SongAndArtistMap, comp).validate({}).must_equal false
    end
  end


  describe "#save" do
    let (:comp) { SongAndArtist.new(:artist => OpenStruct.new, :song => OpenStruct.new) }
    let (:form) { SongForm.new(SongAndArtistMap, comp) }

    before { form.validate("name" => "Diesel Boy") }

    it "pushes data to models" do
      form.save

      comp.artist.name.must_equal "Diesel Boy"
      comp.song.title.must_equal nil
    end

    describe "#save with block" do
      it "provides data block argument" do
        hash = {}

        form.save do |data, map|
          hash[:name]   = data.name
          hash[:title]  = data.title
        end

        hash.must_equal({:name=>"Diesel Boy", :title=>nil})
      end

      it "provides nested symbolized hash as second block argument" do
        hash = {}

        form.save do |data, map|
          hash = map
        end

        hash.must_equal({:artist=>{:name=>"Diesel Boy"}})
      end
    end
  end
end

# TODO: test errors
