require 'test_helper'

class ModelMapperTest < MiniTest::Spec
  class SongWithArtist < Reform::ModelMapper
    property :title,  :on => :song
    property :name,   :on => :artist
  end

  let (:map) { SongWithArtist.new( :song   => OpenStruct.new(:title => "Disconnect, Disconnect"),
                                    :artist => OpenStruct.new(:name => "Osker")) }

  describe "#to_hash" do
    it "returns key-value form field content" do
      map.to_hash.must_equal({"title"=>"Disconnect, Disconnect", "name"=>"Osker"})
    end
  end

  describe "#to_nested_hash" do
    it "returns nested hash keyed by composition objects" do
      map.to_nested_hash.must_equal({:artist => {"name" => "Osker"}, :song => {"title" => "Disconnect, Disconnect"}})
    end
  end
end