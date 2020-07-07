require "test_helper"

class WriteableTest < MiniTest::Spec
  Location = Struct.new(:country)

  class LocationForm < TestForm
    property :country, writeable: false
  end

  let(:loc) { Location.new("Australia") }
  let(:form) { LocationForm.new(loc) }

  it do
    assert_equal form.country, "Australia"

    form.validate("country" => "Germany") # this usually won't change when submitting.
    assert_equal form.country, "Germany"

    form.sync
    assert_equal loc.country, "Australia" # the writer wasn't called.

    hash = {}
    form.save do |nested|
      hash = nested
    end

    assert_equal hash, "country" => "Germany"
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
    assert_equal form.country, "Australia"

    form.validate("country" => "Germany") # this usually won't change when submitting.
    assert_equal form.country, "Germany"

    form.sync
    assert_equal loc.country, "Australia" # the writer wasn't called.

    hash = {}
    form.save do |nested|
      hash = nested
    end

    assert_equal hash, "country" => "Germany"
  end
end
