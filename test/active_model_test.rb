require 'test_helper'

class NewActiveModelTest < MiniTest::Spec # TODO: move to test/rails/
  class SongForm < Reform::Form
    include Reform::Form::ActiveModel

    property :name
  end

  let (:artist) { Artist.create(:name => "Frank Zappa") }
  let (:form) { SongForm.new(artist) }

  it { form.persisted?.must_equal true }
  it { form.to_key.must_equal [artist.id] }
  it { form.to_param.must_equal "#{artist.id}" }
  it { form.to_model.must_equal form }
  it { form.id.must_equal artist.id }

  describe "::model_name" do
    it { form.class.model_name.must_be_kind_of ActiveModel::Name }
    it { form.class.model_name.to_s.must_equal "NewActiveModelTest::Song" }

    let (:class_with_model) {
      Class.new(Reform::Form) do
        include Reform::Form::ActiveModel

        model :album
      end
    }

    it { class_with_model.model_name.must_be_kind_of ActiveModel::Name }
    it { class_with_model.model_name.to_s.must_equal "Album" }


    let (:subclass_of_class_with_model) {
      Class.new(class_with_model)
    }

    it { subclass_of_class_with_model.model_name.must_be_kind_of ActiveModel::Name }
    it { subclass_of_class_with_model.model_name.to_s.must_equal 'Album' }


    describe "inline with model" do
      let (:form_class) {
        Class.new(Reform::Form) do
          include Reform::Form::ActiveModel

          property :song do
            include Reform::Form::ActiveModel
            model :hit
          end
        end
      }

      let (:inline) { form_class.new(OpenStruct.new(:song => Object.new)).song }

      it { inline.class.model_name.must_be_kind_of ActiveModel::Name }
      it { inline.class.model_name.to_s.must_equal "Hit" }
    end

    describe "inline without model" do
      let (:form_class) {
        Class.new(Reform::Form) do
          include Reform::Form::ActiveModel

          property :song do
            include Reform::Form::ActiveModel
          end

          collection :hits do
            include Reform::Form::ActiveModel
          end
        end
      }

      let (:form) { form_class.new(OpenStruct.new(:hits=>[OpenStruct.new], :song => OpenStruct.new)) }

      it { form.song.class.model_name.must_be_kind_of ActiveModel::Name }
      it { form.song.class.model_name.to_s.must_equal "Song" }
      it "singularizes collection name" do
        form.hits.first.class.model_name.to_s.must_equal "Hit"
      end
    end
  end
end

class FormBuilderCompatTest < MiniTest::Spec
  let (:form_class) {
    Class.new(Reform::Form) do
      include Reform::Form::ActiveModel::FormBuilderMethods

      property :artist do
        property :name
        validates :name, :presence => true
      end

      collection :songs do
        property :title
        property :release_date
        validates :title, :presence => true
      end

      class LabelForm < Reform::Form
        property :name
      end

      property :label, :form => LabelForm
    end
  }

  let (:song) { OpenStruct.new }
  let (:form) { form_class.new(OpenStruct.new(
    :artist => Artist.new(:name => "Propagandhi"),
    :songs  => [song],
    :label  => OpenStruct.new)) }

  it "respects _attributes params hash" do
    form.validate("artist_attributes" => {"name" => "Blink 182"},
      "songs_attributes" => {"0" => {"title" => "Damnit"}})

    form.artist.name.must_equal "Blink 182"
    form.songs.first.title.must_equal "Damnit"
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

  describe "deconstructed date parameters" do
    let(:form_attributes) do
      {
        "artist_attributes" => {"name" => "Blink 182"},
        "songs_attributes" => {"0" => {"title" => "Damnit", "release_date(1i)" => release_year,
          "release_date(2i)" => release_month, "release_date(3i)" => release_day}}
      }
    end
    let(:release_year) { "1997" }
    let(:release_month) { "9" }
    let(:release_day) { "27" }

    describe "with valid parameters" do
      it "creates a date" do
        form.validate(form_attributes)

        form.songs.first.release_date.must_equal Date.new(1997, 9, 27)
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
  end

  it "returns flat errors hash" do
    form.validate("artist_attributes" => {"name" => ""},
      "songs_attributes" => {"0" => {"title" => ""}})
    form.errors.messages.must_equal(:"artist.name" => ["can't be blank"], :"songs.title" => ["can't be blank"])
  end
end

class ActiveModelWithCompositionTest < MiniTest::Spec
   class HitForm < Reform::Form
    include Composition
    include Reform::Form::ActiveModel

    property  :title,           :on => :song
    properties [:name, :genre], :on => :artist # we need to check both ::property and ::properties here!

    model :hit, :on => :song
  end

  let (:rio) { OpenStruct.new(:title => "Rio") }
  let (:duran) { OpenStruct.new }
  let (:form) { HitForm.new(:song => rio, :artist => duran) }

  describe "main form reader #hit" do
    it "delegates to :on model" do
      form.hit.must_equal rio
    end

    it "doesn't delegate when :on missing" do
      class SongOnlyForm < Reform::Form
        include Composition
        include Reform::Form::ActiveModel

        property :title,  :on => :song

        model :song
      end.new(:song => rio, :artist => duran).song.must_equal rio
    end

    # it "delegates when you call ::model" do
    #   class SongOnlyForm < Reform::Form
    #     include Composition
    #     include Reform::Form::ActiveModel

    #     property :title,  :on => :song
    #     model :song

    #     self
    #   end.new(:song => rio, :artist => duran).persisted?
    # end
  end


  it "creates composition readers" do
    skip "we don't want those anymore since they don't represent the form internal state!"
    form.song.must_equal rio
    form.artist.must_equal duran
  end

  it "provides ::model_name" do
    form.class.model_name.must_equal "Hit"
  end

  it "provides #persisted?" do
    HitForm.new(:song => OpenStruct.new.instance_eval { def persisted?; "yo!"; end; self }, :artist => OpenStruct.new).persisted?.must_equal "yo!"
  end

  it "provides #to_key" do
    HitForm.new(:song => OpenStruct.new.instance_eval { def to_key; "yo!"; end; self }, :artist => OpenStruct.new).to_key.must_equal "yo!"
  end

  it "provides #to_param" do
    HitForm.new(:song => OpenStruct.new.instance_eval { def to_param; "yo!"; end; self }, :artist => OpenStruct.new).to_param.must_equal "yo!"
  end

  it "provides #to_model" do
    form = HitForm.new(:song => OpenStruct.new, :artist => OpenStruct.new)
    form.to_model.must_equal form
  end

  it "works with any order of ::model and ::property" do
    class AnotherForm < Reform::Form
      include Composition
      include Reform::Form::ActiveModel

      model :song, :on => :song
      property  :title,  :on => :song
    end


    AnotherForm.new(:song => rio).song.must_equal rio
  end
end
