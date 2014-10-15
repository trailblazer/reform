require 'test_helper'

class SkipUnchangedTest < MiniTest::Spec
  class SongForm < Reform::Form
    include Sync::SkipUnchanged
    register_feature Sync::SkipUnchanged

    property :id
    property :title
    property :image, sync: lambda { |value, *| model.image = "processed via :sync: #{value}" }#, virtual: true
    property :band do
      property :name, sync: lambda { |value, *| model.name = "band, processed: #{value}" }
    end
  end

  Song = Struct.new(:id, :title, :image, :band) do
    def id=(v); raise "never call me #{v.inspect}"; end
  end
  Band = Struct.new(:name)

  let (:song) { Song.new(1, "Injection", Object, Band.new("Rise Against")) }

  # skips when not present in hash + SkipUnchanged.
  it("zhz") do
    form = SongForm.new(song)

    form.validate("title" => "Ready To Fall").must_equal true
    form.sync

    song.id.must_equal 1 # old
    song.title.must_equal "Ready To Fall" # new!
    song.image.must_equal Object # old
    song.band.name.must_equal "Rise Against" # old
  end

  # uses :sync when present in params hash.
  it do
    form = SongForm.new(song)

    form.validate("title" => "Ready To Fall", "image" => Module, "band" => {"name" => Class})
    form.sync

    song.id.must_equal 1
    song.image.must_equal "processed via :sync: Module"
    # nested works.
    song.band.name.must_equal "band, processed: Class"
  end
end


# :virtual is considered with SkipUnchanged
class SkipUnchangedWithVirtualTest < MiniTest::Spec
  Song = Struct.new(:title, :image, :band) do
    def image=(v)
      raise "i should not be called: #{v}"
    end
  end
  Band = Struct.new(:name) do
    def name=(v)
      raise "i should not be called: #{v}"
    end
  end

  let (:form) { HitForm.new(song) }
  let (:song) { Song.new(nil, nil, Band.new) }

  class HitForm < Reform::Form
    include Sync::SkipUnchanged
    register_feature Sync::SkipUnchanged

    property :title
    property :image, virtual: true
    property :band do
      property :name, virtual: true
    end
  end

  it "hhy" do
    form.validate("title" => "Full Throttle", "image" => "Funny photo of Steve Harris", "band" => {"name" => "Iron Maiden"}).must_equal true

    form.sync
    song.title.must_equal "Full Throttle"
    song.image.must_equal nil
    song.band.name.must_equal nil
  end
end