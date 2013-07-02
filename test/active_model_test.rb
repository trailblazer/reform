require 'test_helper'

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