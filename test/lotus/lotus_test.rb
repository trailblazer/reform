require "reform"
require "reform/form/lotus"
require "minitest/autorun"

Reform::Contract.class_eval do
  include Reform::Contract::Validate
  include Reform::Form::Lotus
end

class LotusTest < Minitest::Spec
  Album = Struct.new(:title, :songs, :artist)

  class AlbumForm < Reform::Form


    property :title
    validates :title, presence: true

    property :songs do
      property :name
    end
  end

  it do
    form = AlbumForm.new(Album.new("Show Completo"))

    form.validate(title: "").must_equal false

    form.errors.to_s.must_equal ""
  end
end