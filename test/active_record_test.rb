require 'test_helper'

class ActiveRecordTest < MiniTest::Spec
  let (:form) do
    require 'reform/active_record'
    Class.new(Reform::Form) do
      include Reform::Form::ActiveRecord
      model :artist

      property :name
      property :created_at

      validates_uniqueness_of :name
      validates :created_at, :presence => true # have another property to test if we mix up.
    end.
    new(Artist.new)
  end

  it { form.class.i18n_scope.must_equal :activerecord }

  describe "UniquenessValidator" do
    #  ActiveRecord::Schema.define do
    #    create_table :artists do |table|
    #      table.column :name, :string
    #      table.timestamps
    #    end
    #  end
    # Artist.new(:name => "Racer X").save

    it "allows accessing the database" do
    end

    it "is valid when name is unique" do
      form.validate({"name" => "Paul Gilbert", "created_at" => "November 6, 1966"}).must_equal true
    end

    it "is invalid and shows error when taken" do
      Artist.create(:name => "Racer X")

      form.validate({"name" => "Racer X"}).must_equal false
      form.errors.messages.must_equal({:name=>["has already been taken"], :created_at => ["can't be blank"]})
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
  end

  describe "#save" do
    it "calls model.save" do
      Artist.delete_all
      form.from_hash("name" => "Bad Religion")
      Artist.where(:name => "Bad Religion").size.must_equal 0
      form.save
      Artist.where(:name => "Bad Religion").size.must_equal 1
    end

    it "doesn't call model.save when block is given" do
      Artist.delete_all
      form.from_hash("name" => "Bad Religion")
      form.save {}
      Artist.where(:name => "Bad Religion").size.must_equal 0
    end
  end

  describe 'Album has_many :songs' do
    require 'reform/active_record'
    class AlbumForm < Reform::Form
      include Reform::Form::ActiveRecord
      property :title

      collection :songs do
        include Reform::Form::ActiveRecord
        property :title
        validates :title, :presence => true

        # TODO: nest one level deeper and make sure it saves recursively to the deepest subform
      end

      validates :title, :presence => true
    end

    let(:album_hash) {
      {"title"=>"Album", "songs"=>[{"title"=>"Song 1"}, {"title"=>"Song 2"}]}
    }
    let(:updated_album_hash) {
      {"title"=>"Updated Album", "songs"=>[{"title"=>"Updated Song 1"}, {"title"=>"Updated Song 2"}]}
    }

    describe "create (records don't already exist)" do
      let(:songs) { [Song.new(:title => "Song 1"),
                     Song.new(:title => "Song 2")] }
      let(:album) do
        Album.new.tap do |album|
          album.songs.build
          album.songs.build
        end
      end
      let(:form)  { AlbumForm.new(album) }

      it "saves all objects, including each song" do
        form.to_hash.must_equal({"songs"=>[{}, {}]})
        form.from_hash(album_hash)
        form.to_hash.must_equal(album_hash)
        Album.count.must_equal 0
        Song.count.must_equal 0

        form.save
        Album.count.must_equal 1
        album = Album.first
        album.songs[0].title.must_equal "Song 1"
      end

      it "doesn't call save on any objects when block is given" do
        form.from_hash(album_hash)
        form.save {}
        Album.count.must_equal 0
        Song.count.must_equal 0
      end

      after { Album.delete_all; Song.delete_all }
    end

    describe "update existing records" do
      let(:songs) { [Song.create!(:title => "Song 1"),
                     Song.create!(:title => "Song 2")] }
      let(:album) do
        Album.create!(
          :title  => "Album",
          :songs  => songs
        )
      end
      let(:form)  { AlbumForm.new(album) }

      it "saves all objects, including each song" do
        form.to_hash.must_equal(album_hash)
        Album.count.must_equal 1
        album = Album.first
        album.songs.size.must_equal 2
        form.from_hash(updated_album_hash)

        form.save
        Album.count.must_equal 1
        album = Album.first
        album.songs[0].title.must_equal "Updated Song 1"
      end

      it "doesn't call save on any objects when block is given" do
        form.from_hash(updated_album_hash)
        form.save {}
        Album.first.songs[0].title.must_equal "Song 1"
      end

      after { Album.delete_all; Song.delete_all }
    end
  end
end
