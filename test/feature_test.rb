class FeatureInheritanceTest < BaseTest
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  module Date
    def date
      "May 16"
    end

    def self.included(includer)
      includer.send :register_feature, self
    end
  end

  # module Name
  #   def name
  #     "Violins"
  #   end
  # end

  class AlbumForm < TestForm
    feature Date # feature.
    property :name

    collection :songs do
      property :title

      property :composer do
        property :name
      end
    end

    property :artist do
      property :name
    end
  end

  let(:song)               { Song.new("Broken") }
  let(:song_with_composer) { Song.new("Resist Stance", nil, composer) }
  let(:composer)           { Artist.new("Greg Graffin") }
  let(:artist)             { Artist.new("Bad Religion") }
  let(:album)              { Album.new("The Dissent Of Man", [song, song_with_composer], artist) }

  let(:form) { AlbumForm.new(album) }

  it do
    _(form.date).must_equal "May 16"
    _(form.songs[0].date).must_equal "May 16"
  end

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
