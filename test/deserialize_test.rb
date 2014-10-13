require 'test_helper'
require 'reform/form/json'

class DeserializeTest < BaseTest
  class AlbumContract < Reform::Form
    include Reform::Form::ActiveModel::FormBuilderMethods # overrides #update!, too.

    include Reform::Form::JSON

    property :title
    validates :title, :presence => true, :length => {:minimum => 3}

    property :hit do
      property :title
      validates :title, :presence => true
    end

    property :band do # yepp, people do crazy stuff like that.
      validates :label, :presence => true

      property :label do
        property :name
        validates :name, :presence => true
      end
    end
  end

  let (:album) { Album.new(nil, Song.new, [Song.new, Song.new], Band.new(Label.new("Fat Wreck")) ) }
  subject { AlbumContract.new(album) }

  let (:json) { '{"hit":{"title":"Sacrifice"},"title":"Second Heat","songs":[{"title":"Heart Of A Lion"}],"band":{"label":{"name":"Fat Wreck"}}}' }

  it do
    subject.validate(json)
    subject.band.label.name.must_equal "Fat Wreck"
  end
end