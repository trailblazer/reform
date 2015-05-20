require 'test_helper'

class SaveTest < BaseTest
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  class AlbumForm < Reform::Form
    property :name
    validates :name, presence: true

    collection :songs do
      property :title
      validates :title, presence: true

      property :composer do
        property :name
        validates :name, presence: true
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
      @saved
    end
  end


  let (:song)               { Song.new("Broken").extend(Saveable) }
  # let (:song_with_composer) { Song.new("Resist Stance", nil, composer).extend(Saveable) }
  let (:composer)           { Artist.new("Greg Graffin").extend(Saveable) }
  let (:artist)             { Artist.new("Bad Religion").extend(Saveable).extend(Saveable) }
  let (:album)              { Album.new("The Dissent Of Man", [song], artist).extend(Saveable) }

  let (:form) { AlbumForm.new(album) }


  it do
    form.validate("songs" => [{"title" => "Fixed"}])

    form.save

    album.saved?.must_equal true
    album.songs[0].title.must_equal "Fixed"
    album.songs[0].saved?.must_equal true
    album.artist.saved?.must_equal nil
  end
end


# class SaveWithDynamicOptionsTest < MiniTest::Spec
#   Song = Struct.new(:id, :title, :length) do
#     include Saveable
#   end

#   class SongForm < Reform::Form
#     property :title#, save: false
#     property :length, virtual: true
#   end

#   let (:song) { Song.new }
#   let (:form) { SongForm.new(song) }

#   # we have access to original input value and outside parameters.
#   it "xxx" do
#     form.validate("title" => "A Poor Man's Memory", "length" => 10)
#     length_seconds = 120
#     form.save(length: lambda { |value, options| form.model.id = "#{value}: #{length_seconds}" })

#     song.title.must_equal "A Poor Man's Memory"
#     song.length.must_equal nil
#     song.id.must_equal "10: 120"
#   end
# end