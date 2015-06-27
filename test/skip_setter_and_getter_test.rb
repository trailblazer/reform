require "test_helper"

# Overridden setter won't be called in setup.
# Overridden getter won't be called in sync.
class SetupSkipSetterAndGetterTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:title, :artist)
  Artist = Struct.new(:name)

  class AlbumForm < Reform::Form
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

  let (:artist) { Artist.new("Bad Religion") }


  it do
    album = Album.new("Greatest Hits", artist)
    form  = AlbumForm.new(album)

    form.title.must_equal "GREATEST HITS"
    form.artist.name.must_equal "bad religion"

    form.validate("title" => "Resiststance", "artist" => {"name" => "Greg Graffin"})

    form.title.must_equal "ECNATSTSISER" # first, setter called, then getter.
    form.artist.name.must_equal "greg graffi"

    form.sync

    album.title.must_equal "ecnatstsiseR" # setter called, but not getter.
    album.artist.name.must_equal "Greg Graffi"
  end
end