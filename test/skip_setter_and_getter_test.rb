require "test_helper"

# Overridden setter won't be called in setup.
# Overridden getter won't be called in sync.
class SetupSkipSetterAndGetterTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:title, :artist)
  Artist = Struct.new(:name)

  class AlbumForm < TestForm
    property :title

    def title
      super.upcase
    end

    def title=(v)
      super v.reverse
    end

    property :artist do
      property :name

      def name
        super.downcase
      end

      def name=(v)
        super v.chop
      end
    end
  end

  let(:artist) { Artist.new("Bad Religion") }

  it do
    album = Album.new("Greatest Hits", artist)
    form  = AlbumForm.new(album)

    assert_equal form.title, "GREATEST HITS"
    assert_equal form.artist.name, "bad religion"

    form.validate("title" => "Resiststance", "artist" => {"name" => "Greg Graffin"})

    assert_equal form.title, "ECNATSTSISER" # first, setter called, then getter.
    assert_equal form.artist.name, "greg graffi"

    form.sync

    assert_equal album.title, "ecnatstsiseR" # setter called, but not getter.
    assert_equal album.artist.name, "Greg Graffi"
  end
end
