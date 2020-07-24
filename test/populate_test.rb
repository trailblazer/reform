require "test_helper"

class PopulatorTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  class AlbumForm < TestForm
    property :name, populator: ->(options) { self.name = options[:fragment].reverse }
    validation do
      params { required(:name).filled }
    end

    collection :songs,
               populator: ->(fragment:, model:, index:, **) {
                 (item = model[index]) ? item : model.insert(index, Song.new)
               } do
      property :title
      validation do
        params { required(:title).filled }
      end

      property :composer, populator: ->(options) { options[:model] || self.composer = Artist.new } do
        property :name
        validation do
          params { required(:name).filled }
        end
      end
    end

    # property :artist, populator: lambda { |fragment, options| (item = options.binding.get) ? item : Artist.new } do
    # NOTE: we have to document that model here is the twin!
    property :artist, populator: ->(options) { options[:model] || self.artist = Artist.new } do
      property :name
    end
  end

  let(:song)               { Song.new("Broken") }
  let(:song_with_composer) { Song.new("Resist Stance", nil, composer) }
  let(:composer)           { Artist.new("Greg Graffin") }
  let(:artist)             { Artist.new("Bad Religion") }
  let(:album)              { Album.new("The Dissent Of Man", [song, song_with_composer], artist) }

  let(:form) { AlbumForm.new(album) }

  it "runs populator on scalar" do
    form.validate(
      "name" => "override me!"
    )

    assert_equal form.name, "!em edirrevo"
  end

  # changing existing property :artist.
  # TODO: check with artist==nil
  it do
    old_id = artist.object_id

    form.validate(
      "artist" => {"name" => "Marcus Miller"}
    )

    assert_equal form.artist.model.object_id, old_id
  end

  # use populator for default value on scalars?

  # adding to collection via :populator.
  # valid.
  it "yyy" do
    assert form.validate(
      "songs"  => [{"title" => "Fallout"}, {"title" => "Roxanne"},
        {"title" => "Rime Of The Ancient Mariner"}, # new song.
        {"title" => "Re-Education", "composer" => {"name" => "Rise Against"}}], # new song with new composer.
    )

    assert_equal form.errors.messages.inspect, "{}"

    # form has updated.
    assert_equal form.name, "The Dissent Of Man"
    assert_equal form.songs[0].title, "Fallout"
    assert_equal form.songs[1].title, "Roxanne"
    assert_equal form.songs[1].composer.name, "Greg Graffin"

    form.songs[1].composer.model.is_a? Artist

    assert_equal form.songs[1].title, "Roxanne"
    assert_equal form.songs[2].title, "Rime Of The Ancient Mariner" # new song added.
    assert_equal form.songs[3].title, "Re-Education"
    assert_equal form.songs[3].composer.name, "Rise Against"
    assert_equal form.songs.size, 4
    assert_equal form.artist.name, "Bad Religion"

    # model has not changed, yet.
    assert_equal album.name, "The Dissent Of Man"
    assert_equal album.songs[0].title, "Broken"
    assert_equal album.songs[1].title, "Resist Stance"
    assert_equal album.songs[1].composer.name, "Greg Graffin"
    assert_equal album.songs.size, 2
    assert_equal album.artist.name, "Bad Religion"
  end
end

class PopulateWithMethodTest < Minitest::Spec
  Album = Struct.new(:title)

  class AlbumForm < TestForm
    property :title, populator: :title!

    def title!(options)
      self.title = options[:fragment].reverse
    end
  end

  let(:form) { AlbumForm.new(Album.new) }

  it "runs populator method" do
    form.validate("title" => "override me!")

    assert_equal form.title, "!em edirrevo"
  end
end

class PopulateWithCallableTest < Minitest::Spec
  Album = Struct.new(:title)

  class TitlePopulator
    include Uber::Callable

    def call(form, options)
      form.title = options[:fragment].reverse
    end
  end

  class AlbumForm < TestForm
    property :title, populator: TitlePopulator.new
  end

  let(:form) { AlbumForm.new(Album.new) }

  it "runs populator method" do
    form.validate("title" => "override me!")

    assert_equal form.title, "!em edirrevo"
  end
end

class PopulateWithProcTest < Minitest::Spec
  Album = Struct.new(:title)

  TitlePopulator = ->(options) do
    options[:represented].title = options[:fragment].reverse
  end

  class AlbumForm < TestForm
    property :title, populator: TitlePopulator
  end

  let(:form) { AlbumForm.new(Album.new) }

  it "runs populator method" do
    form.validate("title" => "override me!")

    assert_equal form.title, "!em edirrevo"
  end
end

class PopulateIfEmptyTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  let(:song)               { Song.new("Broken") }
  let(:song_with_composer) { Song.new("Resist Stance", nil, composer) }
  let(:composer)           { Artist.new("Greg Graffin") }
  let(:artist)             { Artist.new("Bad Religion") }
  let(:album)              { Album.new("The Dissent Of Man", [song, song_with_composer], artist) }

  class AlbumForm < TestForm
    property :name

    collection :songs,
      populate_if_empty: Song do                                                # class name works.

      property :title
      validation do
        params { required(:title).filled }
      end

      property :composer, populate_if_empty: :populate_composer! do # lambda works, too. in form context.
        property :name
        validation do
          params { required(:name).filled }
        end
      end

    private
      def populate_composer!(options)
        Artist.new
      end
    end

    property :artist, populate_if_empty: ->(args) { create_artist(args[:fragment], args[:user_options]) } do # methods work, too.
      property :name
    end

    private
    class Sting < Artist
      attr_accessor :args
    end
    def create_artist(input, user_options)
      Sting.new.tap { |artist| artist.args = ([input, user_options].to_s) }
    end
  end

  let(:form) { AlbumForm.new(album) }

  it do
    assert_equal form.songs.size, 2

    assert form.validate(
      "songs" => [{"title" => "Fallout"}, {"title" => "Roxanne"},
        {"title" => "Rime Of The Ancient Mariner"}, # new song.
        {"title" => "Re-Education", "composer" => {"name" => "Rise Against"}}], # new song with new composer.
    )

    assert_equal form.errors.messages.inspect, "{}"

    # form has updated.
    assert_equal form.name, "The Dissent Of Man"
    assert_equal form.songs[0].title, "Fallout"
    assert_equal form.songs[1].title, "Roxanne"
    assert_equal form.songs[1].composer.name, "Greg Graffin"
    assert_equal form.songs[1].title, "Roxanne"
    assert_equal form.songs[2].title, "Rime Of The Ancient Mariner" # new song added.
    assert_equal form.songs[3].title, "Re-Education"
    assert_equal form.songs[3].composer.name, "Rise Against"
    assert_equal form.songs.size, 4
    assert_equal form.artist.name, "Bad Religion"

    # model has not changed, yet.
    assert_equal album.name, "The Dissent Of Man"
    assert_equal album.songs[0].title, "Broken"
    assert_equal album.songs[1].title, "Resist Stance"
    assert_equal album.songs[1].composer.name, "Greg Graffin"
    assert_equal album.songs.size, 2
    assert_equal album.artist.name, "Bad Religion"
  end

  # trigger artist populator. lambda calling form instance method.
  it "xxxx" do
    form = AlbumForm.new(album = Album.new)
    form.validate("artist" => {"name" => "From Autumn To Ashes"})

    assert_equal form.artist.name, "From Autumn To Ashes"
    # test lambda was executed in form context.
    assert form.artist.model.is_a? AlbumForm::Sting
    # test lambda block arguments.
    assert_equal form.artist.model.args.to_s, "[{\"name\"=>\"From Autumn To Ashes\"}, nil]"

    assert_nil album.artist
  end
end

# delete songs while deserializing.
class PopulateIfEmptyWithDeletionTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)

  let(:song)  { Song.new("Broken") }
  let(:song2) { Song.new("Resist Stance") }
  let(:album) { Album.new("The Dissent Of Man", [song, song2]) }

  class AlbumForm < TestForm
    property :name

    collection :songs,
      populate_if_empty: Song, skip_if: :delete_song! do

      property :title
      validation do
        params { required(:title).filled }
      end
    end

    def delete_song!(options)
      songs.delete(songs[0]) and return true if options[:fragment]["title"] == "Broken, delete me!"
      false
    end
  end

  let(:form) { AlbumForm.new(album) }

  it do
    assert form.validate(
      "songs" => [{"title" => "Broken, delete me!"}, {"title" => "Roxanne"}]
    )

    assert_equal form.errors.messages.inspect, "{}"

    assert_equal form.songs.size, 1
    assert_equal form.songs[0].title, "Roxanne"
  end
end

class PopulateWithFormKeyTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)

  let(:song)  { Song.new('Broken') }
  let(:song2) { Song.new('Resist Stance') }
  let(:album) { Album.new('The Dissent Of Man', [song, song2]) }

  class SongForm < TestForm
    property :title

    validation do
      params { required(:title).filled }
    end
  end

  class AlbumForm < TestForm
    property :name

    collection :songs, form: SongForm, populator: :populator!, model_identifier: :title

    def populator!(fragment:, **)
      item = songs.find { |song| song.title == fragment['title'] }
      if item && fragment['delete'] == '1'
        songs.delete(item)
        return skip!
      end
      item || songs.append(Song.new)
    end
  end

  let(:form) { AlbumForm.new(album) }

  it do
    assert_equal 2, form.songs.size

    assert form.validate(
      'songs' => [
        { 'title' => 'Broken' },
        { 'title' => 'Resist Stance' },
        { 'title' => 'Rime Of The Ancient Mariner' }
      ]
    )

    assert_equal 3, form.songs.size

    assert form.validate(
      'songs' => [
        { 'title' => 'Broken', 'delete' => '1' },
        { 'title' => 'Resist Stance' },
        { 'title' => 'Rime Of The Ancient Mariner' }
      ]
    )
    assert_equal 2, form.songs.size
    assert_equal 'Resist Stance', form.songs.first.title
    assert_equal 'Rime Of The Ancient Mariner', form.songs.last.title
  end
end
