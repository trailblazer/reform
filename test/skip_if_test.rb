require 'test_helper'

class SkipIfTest < BaseTest

  class AlbumForm < Reform::Form
    property :title

    property :hit, skip_if: lambda { |fragment, *| fragment["title"].blank? } do
      property :title
      validates :title, presence: true
    end

    collection :songs, skip_if: :skip_song?, populate_if_empty: BaseTest::Song do
      property :title
    end

    def skip_song?(fragment, options)
      fragment["title"].nil?
    end
  end


  let (:hit) { Song.new }
  let (:album) { Album.new(nil, hit, [], nil) }

  # deserializes when present.
  it do
    form = AlbumForm.new(album)
    form.validate("hit" => {"title" => "Altar Of Sacrifice"}).must_equal true
    form.hit.title.must_equal "Altar Of Sacrifice"
  end

  # skips deserialization when not present.
  it do
    form = AlbumForm.new(Album.new)
    form.validate("hit" => {"title" => ""}).must_equal true
    form.hit.must_equal nil # hit hasn't been deserialised.
  end

  # skips deserialization when not present.
  it do
    form = AlbumForm.new(Album.new(nil, nil, []))
    form.validate("songs" => [{"title" => "Waste Of Breath"}, {"title" => nil}]).must_equal true
    form.songs.size.must_equal 1
    form.songs[0].title.must_equal "Waste Of Breath"
  end
end

class SkipIfAllBlankTest < BaseTest
  # skip_if: :all_blank"
  class AlbumForm < Reform::Form
    collection :songs, skip_if: :all_blank, populate_if_empty: BaseTest::Song do
      property :title
      property :length
    end
  end

  # create only one object.
  it do
    form = AlbumForm.new(OpenStruct.new(songs: []))
    form.validate("songs" => [{"title"=>"Apathy"}, {"title"=>"", "length" => ""}]).must_equal true
    form.songs.size.must_equal 1
    form.songs[0].title.must_equal "Apathy"
  end
end