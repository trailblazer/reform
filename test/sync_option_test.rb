require 'test_helper'

class SyncOptionTest < MiniTest::Spec
  class SongForm < Reform::Form
    include Sync::SkipUnchanged
    register_feature Sync::SkipUnchanged

    property :title
    property :image, sync: lambda { |value, *| model.image = "processed via :sync: #{value}" }#, virtual: true
    property :band do
      property :name, sync: lambda { |value, *| model.name = "band, processed: #{value}" }
    end
  end

  Song = Struct.new(:title, :image, :band)
  Band = Struct.new(:name)

  let (:song) { Song.new("Injection", Object, Band.new("Rise Against")) }

  # skips when not present in hash + SkipUnchanged.
  it("zhz") do
    form = SongForm.new(song)

    form.validate("title" => "Ready To Fall")
    form.sync

    song.title.must_equal "Ready To Fall" # new!
    song.image.must_equal Object # old
    song.band.name.must_equal "Rise Against" # old
  end

  # uses :sync when present in params hash.
  it do
    form = SongForm.new(song)

    form.validate("title" => "Ready To Fall", "image" => Module, "band" => {"name" => Class})
    form.sync

    song.image.must_equal "processed via :sync: Module"
    # nested works.
    song.band.name.must_equal "band, processed: Class"
  end


  let (:band) { Band.new("Metallica") }
  let (:form) { BandForm.new(band) }

  describe ":sync allows you conditionals" do
    class BandForm < Reform::Form
      property :name, sync: lambda { |value, options| options.user_options[:form].changed?(:name) ? model.name = value : nil } # change if it hasn't changed
    end

    # don't set name, didn't change.
    it do
      band.instance_exec { def name=(*); raise; end }
      form.validate("name" => "Metallica").must_equal true
      form.sync
      band.name.must_equal "Metallica"
    end

    # update name.
    it do
      form.validate("name" => "Iron Maiden").must_equal true
      form.sync
      form.name.must_equal "Iron Maiden"
    end
  end
end


# :virtual wins over :sync
# class SyncWithVirtualTest < MiniTest::Spec
#   Song = Struct.new(:title, :image, :band)
#   Band = Struct.new(:name)

#   let (:form) { HitForm.new(song) }
#   let (:song) { Song.new("Injection", Object, Band.new("Rise Against")) }

#   class HitForm < Reform::Form
#     include Sync::SkipUnchanged
#     register_feature Sync::SkipUnchanged

#     property :image, sync: lambda { |value, *| model.image = "processed via :sync: #{value}" }
#     property :band do
#       property :name, sync: lambda { |value, *| model.name = "band, processed: #{value}" }, virtual: true
#     end
#   end

#   it "abc" do
#     form.validate("image" => "Funny photo of Steve Harris", "band" => {"name" => "Iron Maiden"}).must_equal true

#     form.sync
#     song.image.must_equal "processed via :sync: Funny photo of Steve Harris"
#     song.band.name.must_equal "Rise Against"
#   end
# end


# :virtual is considered with SkipUnchanged
class SkipUnchangedWithVirtualTest < MiniTest::Spec
  Song = Struct.new(:title, :image, :band) do
    def image=(v)
      raise "i should not be called: #{v.inspect}"
    end
  end
  Band = Struct.new(:name) do
    def name=(v)
      raise "i should not be called: #{v.inspect}"
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
    puts "%%%"
    form.validate("title" => "Full Throttle", "image" => "Funny photo of Steve Harris", "band" => {"name" => "Iron Maiden"}).must_equal true

    form.sync
    song.title.must_equal "Full Throttle"
    song.image.must_equal nil
    song.band.name.must_equal nil
  end
end
