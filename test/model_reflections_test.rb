require 'test_helper'

# Reform::ModelReflections will be the interface between the form object and form builders like simple_form.
class ModelReflectionTest < MiniTest::Spec
  class SongForm < Reform::Form
    include Reform::Form::ActiveRecord
    include Reform::Form::ModelReflections

    model :song

    property :title
    property :artist do
      property :name
    end
  end

  module ColumnForAttribute
    def column_for_attribute(*args)
        "#{self.class}: #{args.inspect}"
    end
  end

  describe "#column_for_attribute" do
    let (:artist) { Artist.new }
    let (:song) { Song.new(artist: artist) }
    let (:form) { SongForm.new(song) }

    # delegate to model.
    it do
      song.extend(ColumnForAttribute)
      artist.extend(ColumnForAttribute)

      form.column_for_attribute(:title).must_equal "Song: [:title]"
      form.artist.column_for_attribute(:name).must_equal "Artist: [:name]"
    end
  end


  class SongWithArtistForm < Reform::Form
    include Reform::Form::ActiveRecord
    include Reform::Form::ModelReflections
    include Reform::Form::Composition

    model :artist

    property :name, on: :artist
    property :title, on: :song
  end

  describe "#column_for_attribute with composition" do
    let (:artist) { Artist.new }
    let (:song) { Song.new }
    let (:form) { SongWithArtistForm.new(artist: artist, song: song) }

    # delegates to respective model.
    it do
      song.extend(ColumnForAttribute)
      artist.extend(ColumnForAttribute)


      form.column_for_attribute(:name).must_equal "Artist: [:name]"
      form.column_for_attribute(:title).must_equal "Song: [:title]"
    end
  end
end