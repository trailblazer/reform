require "test_helper"

class SaveTest < BaseTest
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  class AlbumForm < TestForm
    property :name
    validation do
      params { required(:name).filled }
    end

    collection :songs do
      property :title
      validation do
        params { required(:title).filled }
      end

      property :composer do
        property :name
        validation do
          params { required(:name).filled }
        end
      end
    end

    property :artist, save: false do
      property :name
    end
  end

  module Saveable
    def save
      @saved = true
    end

    def saved?
      defined?(@saved) && @saved
    end
  end

  let(:song)               { Song.new("Broken").extend(Saveable) }
  # let(:song_with_composer) { Song.new("Resist Stance", nil, composer).extend(Saveable) }
  let(:composer)           { Artist.new("Greg Graffin").extend(Saveable) }
  let(:artist)             { Artist.new("Bad Religion").extend(Saveable).extend(Saveable) }
  let(:album)              { Album.new("The Dissent Of Man", [song], artist).extend(Saveable) }

  let(:form) { AlbumForm.new(album) }

  it do
    form.validate("songs" => [{"title" => "Fixed"}])

    form.save

    assert album.saved?
    assert_equal album.songs[0].title, "Fixed"
    assert album.songs[0].saved?
    assert_nil album.artist.saved?
  end

  describe "#sync with block" do
    it do
      form = AlbumForm.new(Album.new("Greatest Hits"))

      form.validate(name: nil) # nil-out the title.

      nested_hash = nil
      form.sync do |hash|
        nested_hash = hash
      end

      assert_equal nested_hash, "name" => nil, "artist" => nil
    end
  end
end

# class SaveWithDynamicOptionsTest < Minitest::Spec
#   Song = Struct.new(:id, :title, :length) do
#     include Saveable
#   end

#   class SongForm < TestForm
#     property :title#, save: false
#     property :length, virtual: true
#   end

#   let(:song) { Song.new }
#   let(:form) { SongForm.new(song) }

#   # we have access to original input value and outside parameters.
#   it "xxx" do
#     form.validate("title" => "A Poor Man's Memory", "length" => 10)
#     length_seconds = 120
#     form.save(length: lambda { |value, options| form.model.id = "#{value}: #{length_seconds}" })

#     song.title.must_equal "A Poor Man's Memory"
#     assert_nil song.length
#     song.id.must_equal "10: 120"
#   end
# end
