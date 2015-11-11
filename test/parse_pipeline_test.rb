require "test_helper"

class ParsePipelineTest < MiniTest::Spec
  Album = Struct.new(:name)

  class AlbumForm < Reform::Form
    property :name, deserializer: { parse_pipeline: ->(input, options) { Representable::Pipeline[->(input, options) { options[:represented].name = input.inspect }] } }
  end

  it "allows passing :parse_pipeline directly" do
    form = AlbumForm.new(Album.new)
    form.validate("name" => "Greatest Hits")
    form.name.must_equal "{\"name\"=>\"Greatest Hits\"}"
  end
end