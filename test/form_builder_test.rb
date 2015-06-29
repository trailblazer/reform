require 'test_helper'

class FormBuilderCompatTest < BaseTest
  class AlbumForm < Reform::Form
    feature Reform::Form::ActiveModel::FormBuilderMethods

    feature Reform::Form::MultiParameterAttributes

    property :artist do
      property :name
      validates :name, :presence => true
    end

    collection :songs do
      feature Reform::Form::ActiveModel::FormBuilderMethods
      property :title
      property :release_date, :multi_params => true
      validates :title, :presence => true
    end

    class LabelForm < Reform::Form
      property :name
    end

    property :label, form: LabelForm

    property :band do
      property :label do
        property :name

        property :location do
          property :postcode
        end
      end
    end
  end


  let (:song) { OpenStruct.new }
  let (:form) { AlbumForm.new(OpenStruct.new(
    :artist => Artist.new(:name => "Propagandhi"),
    :songs  => [song],
    :label  => Label.new,

    :band => Band.new(OpenStruct.new(location: OpenStruct.new))
    )) }

  it "xxxrespects _attributes params hash" do
    form.validate(
      "artist_attributes" => {"name" => "Blink 182"},
      "songs_attributes"  => {"0" => {"title" => "Damnit"}},
      "band_attributes"   => {"label_attributes" => {"name" => "Epitaph", "location_attributes" => {"postcode" => 2481}}})

    form.artist.name.must_equal "Blink 182"
    form.songs.first.title.must_equal "Damnit"
    form.band.label.name.must_equal "Epitaph"
    form.band.label.location.postcode.must_equal 2481
  end

  it "allows nested collection and property to be missing" do
    form.validate({})

    form.artist.name.must_equal "Propagandhi"

    form.songs.size.must_equal 1
    form.songs[0].model.must_equal song # this is a weird test.
  end

  it "defines _attributes= setter so Rails' FB works properly" do
    form.must_respond_to("artist_attributes=")
    form.must_respond_to("songs_attributes=")
    form.must_respond_to("label_attributes=")
  end

  describe "deconstructed datetime parameters" do
    let(:form_attributes) do
      {
        "artist_attributes" => {"name" => "Blink 182"},
        "songs_attributes" => {"0" => {"title" => "Damnit", "release_date(1i)" => release_year,
          "release_date(2i)" => release_month, "release_date(3i)" => release_day,
          "release_date(4i)" => release_hour, "release_date(5i)" => release_minute}}
      }
    end
    let(:release_year) { "1997" }
    let(:release_month) { "9" }
    let(:release_day) { "27" }
    let(:release_hour) { nil }
    let(:release_minute) { nil }

    describe "with valid date parameters" do
      it "creates a date" do
        form.validate(form_attributes)

        form.songs.first.release_date.must_equal Date.new(1997, 9, 27)
      end
    end

    describe "with valid datetime parameters" do
      let(:release_hour) { "10" }
      let(:release_minute) { "11" }

      it "creates a datetime" do
        form.validate(form_attributes)

        form.songs.first.release_date.must_equal Time.new(1997, 9, 27, 10, 11)
      end
    end

    %w(year month day).each do |date_attr|
      describe "when the #{date_attr} is missing" do
        let(:"release_#{date_attr}") { "" }

        it "rejects the date" do
          form.validate(form_attributes)

          form.songs.first.release_date.must_be_nil
        end
      end
    end


    # doesn't modify original params.
    it do
      original = form_attributes.inspect

      form.validate(form_attributes)
      form_attributes.inspect.must_equal original
    end
  end

  it "returns flat errors hash" do
    form.validate("artist_attributes" => {"name" => ""},
      "songs_attributes" => {"0" => {"title" => ""}})
    form.errors.messages.must_equal(:"artist.name" => ["can't be blank"], :"songs.title" => ["can't be blank"])
  end
end
