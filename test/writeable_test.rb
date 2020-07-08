require "test_helper"

class WriteableTest < MiniTest::Spec
  Location = Struct.new(:country)

  class LocationForm < TestForm
    property :country, writeable: false
  end

  let(:loc) { Location.new("Australia") }
  let(:form) { LocationForm.new(loc) }

  it do
    _(form.country).must_equal "Australia"

    form.validate("country" => "Germany") # this usually won't change when submitting.
    _(form.country).must_equal "Germany"

    form.sync
    _(loc.country).must_equal "Australia" # the writer wasn't called.

    hash = {}
    form.save do |nested|
      hash = nested
    end

    _(hash).must_equal("country" => "Germany")
  end
end

# writable option is alias of writeable option.
class WritableTest < MiniTest::Spec
  Location = Struct.new(:country)

  class LocationForm < TestForm
    property :country, writable: false
  end

  let(:loc) { Location.new("Australia") }
  let(:form) { LocationForm.new(loc) }

  it do
    _(form.country).must_equal "Australia"

    form.validate("country" => "Germany") # this usually won't change when submitting.
    _(form.country).must_equal "Germany"

    form.sync
    _(loc.country).must_equal "Australia" # the writer wasn't called.

    hash = {}
    form.save do |nested|
      hash = nested
    end

    _(hash).must_equal("country" => "Germany")
  end
end
