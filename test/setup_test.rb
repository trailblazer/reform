require "test_helper"

class SetupTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  class AlbumForm < Reform::Form
    property :name
    collection :songs do
      property :title

      property :composer do
        property :name
      end
    end

    property :artist do
      property :name
    end
  end

  let (:song)               { Song.new("Broken") }
  let (:song_with_composer) { Song.new("Resist Stance", nil, composer) }
  let (:composer)           { Artist.new("Greg Graffin") }
  let (:artist)             { Artist.new("Bad Religion") }

  describe "with nested objects" do
    let (:album) { Album.new("The Dissent Of Man", [song, song_with_composer], artist) }

    it do
      form = AlbumForm.new(album)

      form.name.must_equal "The Dissent Of Man"
      form.songs[0].title.must_equal "Broken"
      form.songs[0].composer.must_equal nil
      form.songs[1].title.must_equal "Resist Stance"
      form.songs[1].composer.name.must_equal "Greg Graffin"
      form.artist.name.must_equal "Bad Religion"

      # make sure all is wrapped in forms.
      form.songs[0].must_be_kind_of Reform::Form
      form.songs[1].must_be_kind_of Reform::Form
      form.songs[1].composer.must_be_kind_of Reform::Form
      form.artist.must_be_kind_of Reform::Form
    end
  end
end