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


    describe "class named Song::Form" do
      it do
        class Form < Reform::Form
          include Reform::Form::ActiveModel
          self
        end.model_name.to_s.must_equal "NewActiveModelTest"
      end
    end


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


class ActiveModelWithCompositionTest < MiniTest::Spec
   class HitForm < Reform::Form
    include Composition
    include Reform::Form::ActiveModel

    property  :title,         :on => :song
    properties :name, :genre, :on => :artist # we need to check both ::property and ::properties here!

    model :hit, :on => :song
  end

  let (:rio) { OpenStruct.new(:title => "Rio") }
  let (:duran) { OpenStruct.new }
  let (:form) { HitForm.new(:song => rio, :artist => duran) }

  describe "model accessors a la model#[:hit]" do
    it { form.model[:song].must_equal rio }
    it { form.model[:artist].must_equal duran }

    it "doesn't delegate when :on missing" do
      class SongOnlyForm < Reform::Form
        include Composition
        include Reform::Form::ActiveModel

        property :title,  :on => :song

        model :song
      end.new(:song => rio, :artist => duran).model[:song].must_equal rio
    end
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


    AnotherForm.new(:song => rio).model[:song].must_equal rio
  end
end
