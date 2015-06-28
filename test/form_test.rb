require 'test_helper'

class FormTest < MiniTest::Spec
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

  # ::schema
  # TODO: refactor schema tests, this is all covered in Disposable.
  describe "::schema" do
    let (:schema) { AlbumForm.schema }

    # it must be a clone
    it { schema.wont_equal AlbumForm.representer_class }
    it { assert schema < Representable::Decorator }
    it { schema.representable_attrs.get(:title).name.must_equal "title" }

    # hit is clone.
    it { schema.representable_attrs.get(:hit).representer_module.object_id.wont_equal AlbumForm.representer_class.representable_attrs.get(:hit).representer_module.object_id }
    it { assert schema.representable_attrs.get(:hit).representer_module < Representable::Decorator }
    # we delete :prepare from schema.
    it { schema.representable_attrs.get(:hit)[:prepare].must_equal nil }

    # band:label is clone.
    # this test might look ridiculous but it is mission-critical to assert that schema is really a clone and doesn't mess up the original structure.
    let (:label) { schema.representable_attrs.get(:band).representer_module.representable_attrs.get(:label) }
    it { assert label.representer_module < Representable::Decorator }
    it { label.representer_module.object_id.wont_equal AlbumForm.representer_class.representable_attrs.get(:band).representer_module.representer_class.representable_attrs.get(:label).representer_module.object_id }

    # #apply
    it do
      properties = []

      schema.apply do |dfn|
        properties << dfn.name
      end

      properties.must_equal ["title", "hit", "title", "songs", "title", "band", "label", "name"]
    end
  end


  describe "::dup" do
    let (:cloned) { AlbumForm.clone }

    # #dup is called in Op.inheritable_attr(:contract_class), it must be subclass of the original one.
    it { cloned.wont_equal AlbumForm }
    it { AlbumForm.representer_class.wont_equal cloned.representer_class }

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
end