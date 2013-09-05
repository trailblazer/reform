require 'test_helper'

class NewActiveModelTest < MiniTest::Spec # TODO: move to test/rails/
  class SongForm < Reform::Form
    include Reform::Form::ActiveModel::FormBuilderMethods

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
        include Reform::Form::ActiveModel::FormBuilderMethods
        model :album
      end
    }

    it { class_with_model.model_name.must_be_kind_of ActiveModel::Name }
    it { class_with_model.model_name.to_s.must_equal "Album" }
  end
end

class FormBuilderCompatTest < MiniTest::Spec
  let (:form_class) {
    Class.new(Reform::Form) do
      include Reform::Form::ActiveModel::FormBuilderMethods

      property :artist do
        property :name
      end

      collection :songs do
        property :title
      end
    end
  }
# TODO: test when keys are missing!

  it "respects _attributes params hash" do
    form = form_class.new(OpenStruct.new(:artist => Artist.new, :songs => [OpenStruct.new]))

    form.validate("artist_attributes" => {"name" => "Blink 182"},
      "songs_attributes" => {"0" => {"title" => "Damnit"}})

    form.artist.name.must_equal "Blink 182"
    form.songs.first.title.must_equal "Damnit"
  end
end

class ActiveModelTest < MiniTest::Spec
   class HitForm < Reform::Form
    include DSL
    include Reform::Form::ActiveModel

    property  :title,  :on => :song
    properties [:name, :genre],   :on => :artist # we need to check both ::property and ::properties here!

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
        include DSL
        include Reform::Form::ActiveModel

        property :title,  :on => :song

        model :song
      end.new(:song => rio, :artist => duran).song.must_equal rio
    end
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
    HitForm.new(:song => OpenStruct.new.instance_eval { def to_model; "yo!"; end; self }, :artist => OpenStruct.new).to_model.must_equal "yo!"
  end

  it "works with any order of ::model and ::property" do
    class AnotherForm < Reform::Form
      include DSL
      include Reform::Form::ActiveModel

      model :song, :on => :song
      property  :title,  :on => :song
    end


    AnotherForm.new(:song => rio).song.must_equal rio
  end
end