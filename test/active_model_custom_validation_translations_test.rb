require 'test_helper'

class ActiveModelCustomValidationTranslationsTest < MiniTest::Spec
  module SongForm
    class WithBlock < Reform::Form
      model :song
      property :title

      validate do
        errors.add :title, :blank
        errors.add :title, :custom_error_message
      end
    end

    class WithLambda < Reform::Form
      model :song
      property :title

      validate ->{ errors.add :title, :blank
                   errors.add :title, :custom_error_message }
    end

    class WithMethod < Reform::Form
      model :song
      property :title

      validate :custom_validation_method
      def custom_validation_method
        errors.add :title, :blank
        errors.add :title, :custom_error_message
      end
    end
  end


  describe 'when using a default translation' do
    it 'translates the error message when custom validation is used with block' do
      form = SongForm::WithBlock.new(Song.new)
      form.validate({})
      form.errors[:title].must_include "can't be blank"
    end

    it 'translates the error message when custom validation is used with lambda' do
      form = SongForm::WithLambda.new(Song.new)
      form.validate({})
      form.errors[:title].must_include "can't be blank"
    end

    it 'translates the error message when custom validation is used with method' do
      form = SongForm::WithMethod.new(Song.new)
      form.validate({})
      form.errors[:title].must_include "can't be blank"
    end
  end

  describe 'when using a custom translation' do
    it 'translates the error message when custom validation is used with block' do
      form = SongForm::WithBlock.new(Song.new)
      form.validate({})
      form.errors[:title].must_include "Custom Error Message"
    end

    it 'translates the error message when custom validation is used with lambda' do
      form = SongForm::WithLambda.new(Song.new)
      form.validate({})
      form.errors[:title].must_include "Custom Error Message"
    end

    it 'translates the error message when custom validation is used with method' do
      form = SongForm::WithMethod.new(Song.new)
      form.validate({})
      form.errors[:title].must_include "Custom Error Message"
    end
  end
end
