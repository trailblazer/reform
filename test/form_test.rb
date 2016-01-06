require 'test_helper'

class FormTest < MiniTest::Spec
  Artist = Struct.new(:name)

  class AlbumForm < Reform::Form
    property :title

    property :hit do
      property :title
    end

    collection :songs do
      property :title
    end

    property :band do # yepp, people do crazy stuff like that.
      property :label do
        property :name
      end
    end
  end

  # combined property/validates syntax.
  class SongForm < Reform::Form
    property :composer
    property :title, validates: {presence: true}
    properties :genre, :band, validates: {presence: true}
  end
  it do
    form = SongForm.new(OpenStruct.new)
    form.validate({})
    form.errors.to_s.must_equal "{:title=>[\"can't be blank\"], :genre=>[\"can't be blank\"], :band=>[\"can't be blank\"]}"
  end

  describe "::dup" do
    let (:cloned) { AlbumForm.clone }

    # #dup is called in Op.inheritable_attr(:contract_class), it must be subclass of the original one.
    it { cloned.wont_equal AlbumForm }
    it { AlbumForm.definitions.wont_equal cloned.definitions }

    it do
      # currently, forms need a name for validation, even without AM.
      cloned.singleton_class.class_eval do
        def name
          "Album"
        end
      end
      cloned.validates :title, presence: true
      cloned.new(OpenStruct.new).validate({})
    end
  end

  describe "#initialize" do
    class ArtistForm < Reform::Form
      property :name
      property :current_user, virtual: true
    end

    it "allows injecting :virtual options" do
      ArtistForm.new(Artist.new, current_user: Object).current_user.must_equal Object
    end
  end
end
