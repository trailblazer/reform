require 'test_helper'

class WriteableTest < MiniTest::Spec
  Location = Struct.new(:country)

  class LocationForm < Reform::Form
    property :country, writeable: false
  end

  let (:loc) { Location.new("Australia") }
  let (:form) { LocationForm.new(loc) }

  it do
    form.country.must_equal "Australia"

    form.validate("country" => "Germany") # this usually won't change when submitting.
    form.country.must_equal "Germany"

    form.sync
    loc.country.must_equal "Australia" # the writer wasn't called.

    hash = {}
    form.save do |nested|
      hash = nested
    end

    hash.must_equal("country"=> "Germany")
  end
end