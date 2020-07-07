require "test_helper"

class SetupTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  class AlbumForm < TestForm
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

  let(:song)               { Song.new("Broken") }
  let(:song_with_composer) { Song.new("Resist Stance", nil, composer) }
  let(:composer)           { Artist.new("Greg Graffin") }
  let(:artist)             { Artist.new("Bad Religion") }

  describe "with nested objects" do
    let(:album) { Album.new("The Dissent Of Man", [song, song_with_composer], artist) }

    it do
      form = AlbumForm.new(album)

      assert_equal form.name, "The Dissent Of Man"
      assert_equal form.songs[0].title, "Broken"
      assert_nil form.songs[0].composer
      assert_equal form.songs[1].title, "Resist Stance"
      assert_equal form.songs[1].composer.name, "Greg Graffin"
      assert_equal form.artist.name, "Bad Religion"

      # make sure all is wrapped in forms.
      assert form.songs[0].is_a? Reform::Form
      assert form.songs[1].is_a? Reform::Form
      assert form.songs[1].composer.is_a? Reform::Form
      assert form.artist.is_a? Reform::Form
    end
  end
end
