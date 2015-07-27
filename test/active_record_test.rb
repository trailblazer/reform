require 'test_helper'
require 'reform/active_record'

# ActiveRecord::Schema.define do
#   create_table :artists do |table|
#     table.column :name, :string
#     table.timestamps
#   end
#   create_table :songs do |table|
#     table.column :title, :string
#     table.column :artist_id, :integer
#     table.column :album_id, :integer
#     table.timestamps
#   end
#   create_table :albums do |table|
#     table.column :title, :string
#     table.timestamps
#   end
# end
# Artist.new(:name => "Racer X").save

class ActiveRecordTest < MiniTest::Spec
  class SongForm < Reform::Form
    include Reform::Form::ActiveRecord
    model :song

    property :title
    property :created_at

    validates_uniqueness_of :title, scope: [:album_id, :artist_id]
    validates :created_at, :presence => true # have another property to test if we mix up.

    property :artist do
      property :name
      validates_uniqueness_of :name # this currently also tests if Form::AR is included as a feature.
    end
  end

  let(:album)   { Album.create(:title => "Damnation") }
  let(:artist)  { Artist.create(:name => "Opeth") }
  let(:form)    { SongForm.new(Song.new(:artist => Artist.new)) }

  it { form.class.i18n_scope.must_equal :activerecord }

  # uniqueness
  it "has no errors on title when title is unique for the same artist and album" do
    form.validate("title" => "The Gargoyle", "artist_id" => artist.id, "album" => album.id, "created_at" => "November 6, 1966")
    assert_empty form.errors[:title]
  end

  it "has errors on title when title is taken for the same artist and album" do
    skip "replace ActiveModel::Validations with our own, working and reusable gem."
    Song.create(title: "Windowpane", artist_id: artist.id, album_id: album.id)
    form.validate("title" => "Windowpane", "artist_id" => artist.id, "album" => album)
    refute_empty form.errors[:title]
  end

  # nested object taken.
  it "is valid when artist name is unique" do
    form.validate("artist" => {"name" => "Paul Gilbert"}, "title" => "The Gargoyle", "created_at" => "November 6, 1966").must_equal true
  end

  it "is invalid and shows error when taken" do
    Song.delete_all
    Artist.create(:name => "Racer X")

    form.validate("artist" => {"name" => "Racer X"}, "title" => "Ghost Inside My Skin").must_equal false
    form.errors.messages.must_equal({:"artist.name"=>["has already been taken"], :created_at => ["can't be blank"]})
  end

  it "works with Composition" do
    form = Class.new(Reform::Form) do
      include Reform::Form::ActiveRecord
      include Reform::Form::Composition

      property :name, :on => :artist
      validates_uniqueness_of :name
    end.new(:artist => Artist.new)

    Artist.create(:name => "Bad Religion")
    form.validate("name" => "Bad Religion").must_equal false
  end

  describe "#save" do
    # TODO: test 1-n?
    it "calls model.save" do
      Artist.delete_all
      form.validate("artist" => {"name" => "Bad Religion"}, "title" => "Ghost Inside My Skin")
      form.save
      Artist.where(:name => "Bad Religion").size.must_equal 1
    end

    it "doesn't call model.save when block is given" do
      Artist.delete_all
      form.validate("name" => "Bad Religion")
      form.save {}
      Artist.where(:name => "Bad Religion").size.must_equal 0
    end

    it "can access block params using string or hash key" do
      Artist.delete_all
      form.validate("artist" => {"name" => "Paul Gilbert"}, "title" => "The Gargoyle", "created_at" => "November 6, 1966")
      form.save do |params|
        params[:title].must_equal 'The Gargoyle'
        params['title'].must_equal 'The Gargoyle'
      end
    end
  end
end


class PopulateWithActiveRecordTest < MiniTest::Spec
  class AlbumForm < Reform::Form

    property :title

    collection :songs, :populate_if_empty => Song do
      property :title
    end
  end

  let (:album) { Album.new(:songs => []) }
  it do
    form = AlbumForm.new(album)

    form.validate("songs" => [{"title" => "Straight From The Jacket"}])

    # form populated.
    form.songs.size.must_equal 1
    form.songs[0].model.must_be_kind_of Song

    # model NOT populated.
    album.songs.must_equal []


    form.sync

    # form populated.
    form.songs.size.must_equal 1
    form.songs[0].model.must_be_kind_of Song

    # model also populated.
    song = album.songs[0]
    album.songs.must_equal [song]
    song.title.must_equal "Straight From The Jacket"


    if ActiveRecord::VERSION::STRING !~ /^3.0/
      # saving saves association.
      form.save

      album.reload
      song = album.songs[0]
      album.songs.must_equal [song]
      song.title.must_equal "Straight From The Jacket"
    end
  end


  describe "modifying 1., adding 2." do
    let (:song) { Song.new(:title => "Part 2") }
    let (:album) { Album.create.tap { |a| a.songs << song } }

    it do
      form = AlbumForm.new(album)

      id = album.songs[0].id
      assert id > 0

      form.validate("songs" => [{"title" => "Part Two"}, {"title" => "Check For A Pulse"}])

      # form populated.
      form.songs.size.must_equal 2
      form.songs[0].model.must_be_kind_of Song
      form.songs[1].model.must_be_kind_of Song

      # model NOT populated.
      album.songs.must_equal [song]


      form.sync

      # form populated.
      form.songs.size.must_equal 2

      # model also populated.
      album.songs.size.must_equal 2

      # corrected title
      album.songs[0].title.must_equal "Part Two"
      # ..but same song.
      album.songs[0].id.must_equal id

      # and a new song.
      album.songs[1].title.must_equal "Check For A Pulse"
      album.songs[1].persisted?.must_equal true # TODO: with << strategy, this shouldn't be saved.
    end

    describe 'using nested_models_attributes to modify nested collection' do
      class ActiveModelAlbumForm < Reform::Form
        include Reform::Form::ActiveModel
        include Reform::Form::ActiveModel::FormBuilderMethods

        property :title

        collection :songs, :populate_if_empty => Song do
          property :title
        end
      end

      let (:album) { Album.create(:title => 'Greatest Hits') }
      let (:form) { ActiveModelAlbumForm.new(album) }

      it "xxx"do
        form.validate('songs_attributes' => {'0' => {'title' => 'Tango'}})

        # form populated.
        form.songs.size.must_equal 1
        form.songs[0].model.must_be_kind_of Song
        form.songs[0].title.must_equal 'Tango'

        # model NOT populated.
        album.songs.must_equal []

        form.save

        # nested model persisted.
        first_song = album.songs[0]
        assert first_song.id > 0

        # form populated.
        form.songs.size.must_equal 1

        # model also populated.
        album.songs.size.must_equal 1
        album.songs[0].title.must_equal 'Tango'

        # DISCUSS: IfEmpty uses twin.original[index] for syncing. in our case, this is empty, so it will add Tango again.
        form = ActiveModelAlbumForm.new(album)
        form.validate('songs_attributes' => {'0' => {'id' => first_song.id, 'title' => 'Tango nuevo'}, '1' => {'title' => 'Waltz'}})

        # form populated.
        form.songs.size.must_equal 2
        form.songs[0].model.must_be_kind_of Song
        form.songs[1].model.must_be_kind_of Song
        form.songs[0].title.must_equal 'Tango nuevo'
        form.songs[1].title.must_equal 'Waltz'

        # model NOT populated.
        album.songs.size.must_equal 1
        album.songs[0].title.must_equal 'Tango'

        form.save

        # form populated.
        form.songs.size.must_equal 2

        # model also populated.
        album.songs.size.must_equal 2
        album.songs[0].id.must_equal first_song.id
        album.songs[0].persisted?.must_equal true
        album.songs[1].persisted?.must_equal true
        album.songs[0].title.must_equal 'Tango nuevo'
        album.songs[1].title.must_equal 'Waltz'
      end
    end
  end
end



