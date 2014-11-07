require 'test_helper'

class WriteableTest < MiniTest::Spec # TODO: remove me in 2.0.
  Location = Struct.new(:country)

  class LocationForm < Reform::Form
    reform_2_0!

    property :country, writeable: false
  end

  let (:loc) { Location.new("Australia") }
  let (:form) { LocationForm.new(loc) }

  it { form.country.must_equal "Australia" }
  it do
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