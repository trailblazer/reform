require 'test_helper'

class FeatureInheritanceTest < BaseTest
  class AlbumForm < Reform::Form
    # include Reform::Form::ActiveModel
    # include Coercion
    # include MultiParameterAttributes

    property :band do
      property :label do
      end
    end
  end

  subject { AlbumForm.new(Album.new(nil, nil, nil, Band.new(Label.new))) }

  # it { subject.class.include?(Reform::Form::ActiveModel) }
  # it { subject.class.include?(Reform::Form::Coercion) }
  # it { subject.is_a?(Reform::Form::MultiParameterAttributes) }

  # it { subject.band.class.include?(Reform::Form::ActiveModel) }
  # it { subject.band.is_a?(Reform::Form::Coercion) }
  # it { subject.band.is_a?(Reform::Form::MultiParameterAttributes) }

  # it { subject.band.label.is_a?(Reform::Form::ActiveModel) }
  # it { subject.band.label.is_a?(Reform::Form::Coercion) }
  # it { subject.band.label.is_a?(Reform::Form::MultiParameterAttributes) }
end