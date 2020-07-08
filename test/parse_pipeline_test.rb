require "test_helper"

class ParsePipelineTest < MiniTest::Spec
  Album = Struct.new(:name)

  class AlbumForm < TestForm
    property :name, deserializer: {parse_pipeline: ->(input, options) { Representable::Pipeline[->(ipt, opts) { opts[:represented].name = ipt.inspect }] }}
  end

  it "allows passing :parse_pipeline directly" do
    form = AlbumForm.new(Album.new)
    form.validate("name" => "Greatest Hits")
    _(form.name).must_equal "{\"name\"=>\"Greatest Hits\"}"
  end
end
