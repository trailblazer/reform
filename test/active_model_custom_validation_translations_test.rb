require 'test_helper'

class ActiveModelCustomValidationTranslationsTest < MiniTest::Spec
  module SongForm
    class WithBlock < Reform::Form
      property :title

      validate do
        errors.add :title, :blank
      end
    end

    class WithLambda < Reform::Form
      property :title

      validate ->{ errors.add :title, :blank }
    end

    class WithMethod < Reform::Form
      property :title

      validate :custom_validation_method
      def custom_validation_method
        errors.add :title, :blank
      end
    end
  end


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
