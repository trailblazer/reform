require 'test_helper'

class ModelValidationsTest < MiniTest::Spec

  class Album
    include ActiveModel::Validations
    attr_accessor :title, :artist, :other_attribute

    validates :title, :artist, presence: true
    validates :other_attribute, presence: true
  end

  class AlbumRating
    include ActiveModel::Validations

    attr_accessor :rating

    validates :rating, numericality: { greater_than_or_equal_to: 0 }

  end

  class AlbumForm < Reform::Form
    extend ActiveModel::ModelValidations

    property :title
    property :artist_name, from: :artist
    copy_validations_from Album
  end

  class CompositeForm < Reform::Form
    include Composition
    extend ActiveModel::ModelValidations

    model :album

    property :title, on: :album
    property :artist_name, from: :artist, on: :album
    property :rating, on: :album_rating

    copy_validations_from album: Album, album_rating: AlbumRating
  end

  let(:album) { Album.new }

  describe 'non-composite form' do

    let(:album_form) { AlbumForm.new(album) }

    it 'is not valid when title is not present' do
      album_form.validate(artist_name: 'test', title: nil).must_equal false
    end

    it 'is not valid when artist_name is not present' do
      album_form.validate(artist_name: nil, title: 'test').must_equal false
    end

    it 'is valid when title and artist_name is present' do
      album_form.validate(artist_name: 'test', title: 'test').must_equal true
    end

  end

  describe 'composite form' do

    let(:album_rating) { AlbumRating.new }
    let(:composite_form) { CompositeForm.new(album: album, album_rating: album_rating) }

    it 'is valid when all attributes are correct' do
      composite_form.validate(artist_name: 'test', title: 'test', rating: 1).must_equal true
    end

    it 'is invalid when rating is below 0' do
      composite_form.validate(artist_name: 'test', title: 'test', rating: -1).must_equal false
    end

    it 'is invalid when artist_name is missing' do
      composite_form.validate(artist_name: nil, title: 'test', rating: 1).must_equal false
    end

  end

end