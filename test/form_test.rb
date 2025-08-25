require "test_helper"

class FormTest < Minitest::Spec
  Artist = Struct.new(:name)

  class AlbumForm < TestForm
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

  describe "::dup" do
    let(:cloned) { AlbumForm.clone }

    # #dup is called in Op.inheritable_attr(:contract_class), it must be subclass of the original one.
    it { refute_equal cloned, AlbumForm }
    it { refute_equal AlbumForm.definitions, cloned.definitions }

    it do
      # currently, forms need a name for validation, even without AM.
      cloned.singleton_class.class_eval do
        def name
          "Album"
        end
      end

      cloned.validation do
        params { required(:title).filled }
      end

      cloned.new(OpenStruct.new).validate({})
    end
  end

  describe "#initialize" do
    class ArtistForm < TestForm
      property :name
      property :current_user, virtual: true
    end

    it "allows injecting :virtual options" do
      assert_equal ArtistForm.new(Artist.new, current_user: Object).current_user, Object
    end
  end
end
