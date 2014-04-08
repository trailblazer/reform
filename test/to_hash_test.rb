require 'test_helper'

class ToHashTest < BaseTest
  describe "populated" do
    subject { AlbumForm.new(Album.new("Best Of", hit, [Song.new("Fallout"), Song.new("Roxanne")])) }

    it do subject.to_hash.must_equal(
      {"title"=>"Best Of", "hit"=>{"title"=>"Roxanne"}, "songs"=>[{"title"=>"Fallout"}, {"title"=>"Roxanne"}]})
    end

  end
end