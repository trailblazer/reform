require 'test_helper'

class ActiveRecordTest < MiniTest::Spec
  let (:form) do
    require 'reform/active_record'
    Class.new(Reform::Form) do
      include Reform::Form::ActiveRecord
      include Reform::Form::ActiveRecordComposition

      validates_uniqueness_of :name

      property :name,  :on => :artist
      property :title, :on => :song

      model :artist
    end.
    new(artist: Artist.new, song: Song.new)
  end

  describe "#save" do
    it "save the artist" do
      Artist.delete_all
      form.validate("name" => "Bad Religion", "title" => "I love My Computer")
      form.save
      Artist.where(:name => "Bad Religion").size.must_equal 1
    end

    it "save the song" do
      Song.delete_all
      form.validate("name" => "Bad Religion", "title" => "I love My Computer")
      form.save
      Song.where(:title => "I love My Computer").size.must_equal 1
    end

    it "doesn't save the artist when block is given" do
      Artist.delete_all
      form.validate("name" => "Bad Religion")
      form.save {}
      Artist.where(:name => "Bad Religion").size.must_equal 0
    end
  end

  describe "UniquenessValidator" do
    it "works with Composition" do
      Artist.create(:name => "Bad Religion")
      form.validate("name" => "Bad Religion").must_equal false
    end
  end
end
