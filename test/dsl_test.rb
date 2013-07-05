require 'test_helper'

class DslTest < MiniTest::Spec
  class SongForm < Reform::Form
    include DSL

    property  :title,           :on => :song
    properties [:name, :genre], :on => :artist

    validates :name, :title, :genre, :presence => true
  end

  let (:form)   { SongForm.new(:song => song, :artist => artist) }
  let (:song)   { OpenStruct.new(:title => "Rio") }
  let (:artist) { OpenStruct.new(:name => "Duran Duran") }


  # delegation form -> composition works
  it { form.title.must_equal  "Rio" }
  it { form.name.must_equal   "Duran Duran" }


  it "creates Composition for you" do
    form.validate("title" => "Greyhound", "name" => "Frenzal Rhomb").must_equal false
  end

  describe "#save" do
    it "provides data block argument" do
      hash = {}

      form.save do |data, map|
        hash[:name]   = data.name
        hash[:title]  = data.title
      end

      hash.must_equal({:name=>"Duran Duran", :title=>"Rio"})
    end

    it "provides nested symbolized hash as second block argument" do
      hash = {}

      form.save do |data, map|
        hash = map
      end

      hash.must_equal({:song=>{:title=>"Rio"}, :artist=>{:name=>"Duran Duran"}})
    end
  end



  require 'reform/form/coercion'
  it "allows coercion" do
    form = Class.new(Reform::Form) do
      include Reform::Form::Coercion

      property :written_at, :type => DateTime
    end.new(OpenStruct.new(:written_at => "31/03/1981"))

    form.written_at.must_be_kind_of DateTime
    form.written_at.must_equal DateTime.parse("Tue, 31 Mar 1981 00:00:00 +0000")
  end

  it "allows coercion in validate" do
    form = Class.new(Reform::Form) do
      include Reform::Form::Coercion

      property :id, :type => Integer
    end.new(OpenStruct.new())

    form.validate("id" => "1")
    form.to_hash.must_equal("id" => 1)
  end
end
