require "test_helper"

class SkipIfTest < BaseTest
  let(:hit) { Song.new }
  let(:album) { Album.new(nil, hit, [], nil) }

  class AlbumForm < TestForm
    property :title

    property :hit, skip_if: ->(options) { options[:fragment]["title"] == "" } do
      property :title
      validation do
        params { required(:title).filled }
      end
    end

    collection :songs, skip_if: :skip_song?, populate_if_empty: BaseTest::Song do
      property :title
    end

    def skip_song?(options)
      options[:fragment]["title"].nil?
    end
  end

  # deserializes when present.
  it do
    form = AlbumForm.new(album)
    _(form.validate("hit" => {"title" => "Altar Of Sacrifice"})).must_equal true
    _(form.hit.title).must_equal "Altar Of Sacrifice"
  end

  # skips deserialization when not present.
  it do
    form = AlbumForm.new(Album.new)
    _(form.validate("hit" => {"title" => ""})).must_equal true
    assert_nil form.hit # hit hasn't been deserialised.
  end

  # skips deserialization when not present.
  it do
    form = AlbumForm.new(Album.new(nil, nil, []))
    _(form.validate("songs" => [{"title" => "Waste Of Breath"}, {"title" => nil}])).must_equal true
    _(form.songs.size).must_equal 1
    _(form.songs[0].title).must_equal "Waste Of Breath"
  end
end

class SkipIfAllBlankTest < BaseTest
  # skip_if: :all_blank"
  class AlbumForm < TestForm
    collection :songs, skip_if: :all_blank, populate_if_empty: BaseTest::Song do
      property :title
      property :length
    end
  end

  # create only one object.
  it do
    form = AlbumForm.new(OpenStruct.new(songs: []))
    _(form.validate("songs" => [{"title" => "Apathy"}, {"title" => "", "length" => ""}])).must_equal true
    _(form.songs.size).must_equal 1
    _(form.songs[0].title).must_equal "Apathy"
  end

  it do
    form = AlbumForm.new(OpenStruct.new(songs: []))
    _(form.validate("songs" => [{"title" => "", "length" => ""}, {"title" => "Apathy"}])).must_equal true
    _(form.songs.size).must_equal 1
    _(form.songs[0].title).must_equal "Apathy"
  end
end

class InvalidOptionsCombinationTest < BaseTest
  it do
    assert_raises(Reform::Form::InvalidOptionsCombinationError) do
      class AlbumForm < TestForm
        collection :songs, skip_if: :all_blank, populator: -> {} do
          property :title
          property :length
        end
      end
    end
  end
end
