require 'test_helper'

unless ActiveModel::VERSION::MAJOR == 3 and ActiveModel::VERSION::MINOR == 0

  class UnexistantTitleValidator < ActiveModel::Validator
    def validate record
      if record.title == 'unexistant_song'
        record.errors.add(:title, 'this title does not exist!')
      end
    end
  end

  class CustomValidationTest < MiniTest::Spec

    class Album
      include ActiveModel::Validations
      attr_accessor :title, :artist

      validates_with UnexistantTitleValidator
    end

    class AlbumForm < Reform::Form
      extend ActiveModel::ModelValidations

      property :title
      property :artist_name, from: :artist
      copy_validations_from Album
    end

    let(:album) { Album.new }

    describe 'non-composite form' do

      let(:album_form) { AlbumForm.new(album) }

      it 'is not valid when title is unexistant_song' do
        album_form.validate(artist_name: 'test', title: 'unexistant_song').must_equal false
      end

      it 'is valid when title is something existant' do
        album_form.validate(artist_name: 'test', title: 'test').must_equal true
      end

    end

  end
end