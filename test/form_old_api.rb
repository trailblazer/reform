require "test_helper"

class FormTest < MiniTest::Spec
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
    it { _(cloned).wont_equal AlbumForm }
    it { _(AlbumForm.definitions).wont_equal cloned.definitions }

    it do
      # currently, forms need a name for validation, even without AM.
      cloned.singleton_class.class_eval do
        def name
          "Album"
        end
      end

      cloned.validation do
        required(:title).filled
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
      _(ArtistForm.new(Artist.new, current_user: Object).current_user).must_equal Object
    end
  end
end
