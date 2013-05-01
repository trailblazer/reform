require 'test_helper'

class ReformTest < MiniTest::Spec
  let (:duran)  { OpenStruct.new(:name => "Duran Duran") }
  let (:rio)    { OpenStruct.new(:title => "Rio") }

  let (:form) { SongForm.new(SongAndArtistMap, comp) }

  class SongAndArtistMap < Representable::Decorator
    include Representable::Hash
    property :name, on: :artist
    property :title, on: :song
  end

  class SongForm < Form
  end

  describe "Composition" do
    class SongAndArtist < Reform::Composition
      map SongAndArtistMap.representable_attrs
    end

    let (:comp) { SongAndArtist.new(:artist => OpenStruct.new, :song => rio) }

    it "delegates to models as defined" do
      comp.name.must_equal nil
      comp.title.must_equal "Rio"
    end

    it "raises when non-mapped property" do
      assert_raises NoMethodError do
        comp.raise_an_exception
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
        form.validate(:name => "Duran Duran")

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

  describe "what" do
    let (:comp) { SongAndArtist.new(:artist => OpenStruct.new, :song => OpenStruct.new) }
    let (:form) { SongForm.new(SongAndArtistMap, comp) }

    it "passes processed form data as block argument" do
      form.validate(:name => "Diesel Boy")

      artist = OpenStruct.new
      map_from_block = {}

      form.save do |data, map|
        artist.name = data.name
        # nice to have: artist.update_attributes(map.artist)
        map_from_block = map  # we want a hash here for now!
      end

      artist.name.must_equal "Diesel Boy"
      map_from_block.must_equal({:artist=>{"name"=>"Diesel Boy"}#, :song=>{"title"=>nil}
        })
    end
  end
end

# TODO: test errors
