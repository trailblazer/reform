require "test_helper"
require "representable/json"

class DeserializeTest < Minitest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:title, :artist)
  Artist = Struct.new(:name, :callname)

  class JsonAlbumForm < TestForm
    module Json
      def deserialize(params)
        deserializer.new(self).
          # extend(Representable::Debug).
          from_json(params)
      end

      def deserializer
        Disposable::Rescheme.from(self.class,
          include:          [Representable::JSON],
          superclass:       Representable::Decorator,
          definitions_from: ->(inline) { inline.definitions },
          options_from:     :deserializer,
          exclude_options:  [:populator]
        )
      end
    end
    include Json

    property :title
    property :artist, populate_if_empty: Artist do
      property :name
    end
  end

  let(:artist) { Artist.new("A-ha") }
  it do
    artist_id = artist.object_id

    form = JsonAlbumForm.new(Album.new("Best Of", artist))
    json = MultiJson.dump({title: "Apocalypse Soon", artist: {name: "Mute"}})

    form.validate(json)

    assert_equal form.title, "Apocalypse Soon"
    assert_equal form.artist.name, "Mute"
    assert_equal form.artist.model.object_id, artist_id
  end

  describe "infering the deserializer from another form should NOT copy its populators" do
    class CompilationForm < TestForm
      property :artist, populator: ->(options) { self.artist = Artist.new(nil, options[:fragment].to_s) } do
        property :name
      end

      def deserializer
        super(JsonAlbumForm, include: [Representable::Hash])
      end
    end

    # also tests the Form#deserializer API. # FIXME.
    it "uses deserializer inferred from JsonAlbumForm but deserializes/populates to CompilationForm" do
      form = CompilationForm.new(Album.new)
      form.validate("artist" => {"name" => "Horowitz"}) # the deserializer doesn't know symbols.
      form.sync
      assert_equal form.artist.model.name, "Horowitz"
      assert_equal Object.new.instance_eval(form.artist.model.callname), {"name" => "Horowitz"}
    end
  end
end

class ValidateWithBlockTest < Minitest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:title, :artist)
  Artist = Struct.new(:name)

  class AlbumForm < TestForm
    property :title
    property :artist, populate_if_empty: Artist do
      property :name
    end
  end

  it do
    album = Album.new
    form  = AlbumForm.new(album)
    json  = MultiJson.dump({title: "Apocalypse Soon", artist: {name: "Mute"}})

    deserializer = Disposable::Rescheme.from(AlbumForm,
      include:          [Representable::JSON],
      superclass:       Representable::Decorator,
      definitions_from: ->(inline) { inline.definitions },
      options_from:     :deserializer
    )

    assert form.validate(json) { |params|
      deserializer.new(form).from_json(params)
    } # with block must return result, too.

    assert_equal form.title, "Apocalypse Soon"
    assert_equal form.artist.name, "Mute"
  end
end
