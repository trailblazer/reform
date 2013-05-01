require 'test_helper'

class ReformTest < MiniTest::Spec
  describe "what" do
    class SongAndArtistMap < Reform::ModelMapper
      property :name, on: :artist, :render_nil => true
      property :track, on: :song, :render_nil => true
    end

    class SongForm < Form
    end

    let (:map) { SongAndArtistMap.new(:artist => OpenStruct.new, :song => OpenStruct.new) }
    let (:form) { SongForm.new(map) }

    # TODO: test emtpy SongAndArtistMap.new(:artist => OpenStruct.new, :song => OpenStruct.new)

    it "passes processed form data as block argument" do
      form.validate(:name => "Diesel Boy")

      artist = OpenStruct.new
      song_hash = {}

      form.save do |data, map|
        artist.name = data.name
        # nice to have: artist.update_attributes(map.artist)
        song_hash = map[:song]  # we want a hash here for now!
      end

      artist.name.must_equal "Diesel Boy"
      song_hash.must_equal({:track => nil})
    end
  end
end
