require 'test_helper'

class DslTest < MiniTest::Spec
  class SongForm < Reform::Form
    include DSL

    property  :title,  :on => :song
    properties [:name, :genre],   :on => :artist

    validates :name, :title, :genre, presence: true
  end

  let (:form) { SongForm.new(:song => OpenStruct.new(:title => "Rio"), :artist => OpenStruct.new()) }

  it "works by creating Representer and Composition for you" do
    form.validate("title" => "Greyhound", "name" => "Frenzal Rhomb").must_equal false
  end
end

require 'reform/form/active_model'
class ActiveModelTest < MiniTest::Spec
   class SongForm < Reform::Form
    include DSL
    include Reform::Form::ActiveModel

    property  :title,  :on => :song
    properties [:name, :genre],   :on => :artist

    model :song, :on => :song
  end

  let (:rio) { OpenStruct.new(:title => "Rio") }
  let (:form) { SongForm.new(:song => rio, :artist => OpenStruct.new) }

  it "creates model readers" do
    form.song.must_equal rio
  end

  it "provides ::model_name" do
    form.class.model_name.must_equal "Song"
  end

  it "provides #persisted?" do
    SongForm.new(:song => OpenStruct.new.instance_eval { def persisted?; "yo!"; end; self }, :artist => OpenStruct.new).persisted?.must_equal "yo!"
  end

  it "provides #to_key" do
    SongForm.new(:song => OpenStruct.new.instance_eval { def to_key; "yo!"; end; self }, :artist => OpenStruct.new).to_key.must_equal "yo!"
  end

  it "provides #to_param" do
    SongForm.new(:song => OpenStruct.new.instance_eval { def to_param; "yo!"; end; self }, :artist => OpenStruct.new).to_param.must_equal "yo!"
  end
end