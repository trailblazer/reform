require 'test_helper'

class MapperTest < MiniTest::Spec

  describe "Form::Mapper" do
    class SongAndArtistComposition < Form::Mapper
      attribute :name, on: :artist
      attribute :track, on: :song
    end

    let (:form_mapper) { SongAndArtistComposition.new(:artist => OpenStruct.new(:name => "Killers"), :song => OpenStruct.new(:track => "Mr Brightside")) }

    it "converts form attributes into an easy to use hash" do
      valid_hash = {:artist => {:name => "Killers"}, :song => {:track => "Mr Brightside"}}
      form_mapper.to_nested_hash.must_equal valid_hash
    end
  end

end