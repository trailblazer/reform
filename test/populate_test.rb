require "test_helper"

class PopulatorTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  class AlbumForm < Reform::Form
    property :name
    validates :name, presence: true

    collection :songs, pass_options: true,
      populator: lambda { |fragment, collection, index, options|
        # collection = options.binding.get # we don't need this anymore as this comes in for free!
        (item = collection[index]) ? item : collection.insert(index, Song.new) } do

      property :title
      validates :title, presence: true

      property :composer, populator: lambda { |fragment, model, *|  model || Artist.new } do
        property :name
        validates :name, presence: true
      end
    end

    # property :artist, populator: lambda { |fragment, options| (item = options.binding.get) ? item : Artist.new } do
    property :artist, populator: lambda { |fragment, model, *| model || Artist.new } do
      property :name
    end
  end

  let (:song)               { Song.new("Broken") }
  let (:song_with_composer) { Song.new("Resist Stance", nil, composer) }
  let (:composer)           { Artist.new("Greg Graffin") }
  let (:artist)             { Artist.new("Bad Religion") }
  let (:album)              { Album.new("The Dissent Of Man", [song, song_with_composer], artist) }

  let (:form) { AlbumForm.new(album) }

  # valid.
  it do
    form.validate(
      "name"   => "Best Of",
      "songs"  => [{"title" => "Fallout"}, {"title" => "Roxanne", "composer" => {"name" => "Sting"}}],
      "artist" => {"name" => "The Police"},
    ).must_equal true

    form.errors.messages.inspect.must_equal "{}"

    # form has updated.
    form.name.must_equal "Best Of"
    form.songs[0].title.must_equal "Fallout"
    form.songs[1].title.must_equal "Roxanne"
    form.songs[1].composer.name.must_equal "Sting"
    form.artist.name.must_equal "The Police"


    # model has not changed, yet.
    album.name.must_equal "The Dissent Of Man"
    album.songs[0].title.must_equal "Broken"
    album.songs[1].title.must_equal "Resist Stance"
    album.songs[1].composer.name.must_equal "Greg Graffin"
    album.artist.name.must_equal "Bad Religion"
  end
end