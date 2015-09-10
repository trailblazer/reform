require 'test_helper'

# Reform::ModelReflections will be the interface between the form object and form builders like simple_form.
class ModelReflectionTest < MiniTest::Spec
  class SongForm < Reform::Form
    include Reform::Form::ActiveRecord
    include Reform::Form::ActiveModel::ModelReflections

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

  module HasAttribute
    def has_attribute?(*args)
      "#{self.class}: has #{args.inspect}"
    end
  end

  module DefinedEnums
    def defined_enums
      {self.class => []}
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

  describe "#has_attribute?" do
    let (:artist) { Artist.new }
    let (:song) { Song.new(artist: artist) }
    let (:form) { SongForm.new(song) }

    # delegate to model.
    it do
      song.extend(HasAttribute)
      artist.extend(HasAttribute)

      form.has_attribute?(:title).must_equal "Song: has [:title]"
      form.artist.has_attribute?(:name).must_equal "Artist: has [:name]"
    end
  end

  describe "#defined_enums" do
    let (:artist) { Artist.new }
    let (:song) { Song.new(artist: artist) }
    let (:form) { SongForm.new(song) }

    # delegate to model.
    it do
      song.extend(DefinedEnums)
      artist.extend(DefinedEnums)

      form.defined_enums.must_include Song
      form.artist.defined_enums.must_include Artist
    end
  end

  describe ".reflect_on_association" do
    let (:artist) { Artist.new }
    let (:song) { Song.new(artist: artist) }
    let (:form) { SongForm.new(song) }

    # delegate to model class.
    it do
      reflection = form.class.reflect_on_association(:artist)
      reflection.must_be_kind_of ActiveRecord::Reflection::AssociationReflection
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

  describe "#defined_enums with composition" do
    let (:artist) { Artist.new }
    let (:song) { Song.new }
    let (:form) { SongWithArtistForm.new(artist: artist, song: song) }

    # delegates to respective model.
    it do
      song.extend(DefinedEnums)
      artist.extend(DefinedEnums)


      form.defined_enums.must_include Song
      form.defined_enums.must_include Artist
    end
  end

  describe "::validators_on" do
    it { assert SongWithArtistForm.validators_on }
  end
end
