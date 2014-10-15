require 'test_helper'

class SyncOptionTest < MiniTest::Spec
  Band = Struct.new(:name)
  let (:band) { Band.new("Metallica") }
  let (:form) { BandForm.new(band) }

  # access to :form!
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

