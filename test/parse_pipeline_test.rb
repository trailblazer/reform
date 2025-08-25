require "test_helper"

class ParsePipelineTest < Minitest::Spec
  Album = Struct.new(:name)

  class AlbumForm < TestForm
    property :name, deserializer: {parse_pipeline: ->(input, options) { Representable::Pipeline[->(ipt, opts) { opts[:represented].name = ipt.inspect }] }}
  end

  it "allows passing :parse_pipeline directly" do
    form = AlbumForm.new(Album.new)
    form.validate("name" => "Greatest Hits")
    assert_equal Object.new.instance_eval(form.name), {"name" => "Greatest Hits"}
  end
end
