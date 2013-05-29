require 'test_helper'

class DslTest < MiniTest::Spec
  class SongForm < Reform::Form
    include DSL

    property  :title,  :on => :song
    properties [:name, :genre],   :on => :artist

    validates :name, :title, :genre, :presence => true
  end

  let (:form) { SongForm.new(:song => OpenStruct.new(:title => "Rio"), :artist => OpenStruct.new()) }

  it "works by creating Representer and Composition for you" do
    form.validate("title" => "Greyhound", "name" => "Frenzal Rhomb").must_equal false
  end

  require 'reform/form/coercion'
  it "allows coercion" do
    form = Class.new(Reform::Form) do
      include Reform::Form::DSL
      include Reform::Form::Coercion

      property :written_at, :type => DateTime, :on => :song
    end.new(:song => OpenStruct.new(:written_at => "31/03/1981"))

    form.written_at.must_be_kind_of DateTime
    form.written_at.must_equal DateTime.parse("Tue, 31 Mar 1981 00:00:00 +0000")
  end
end
