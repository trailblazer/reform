require "test_helper"
require "reform/form/coercion"

class CoercionTest < BaseTest
  class Irreversible
    def self.call(value)
      value * 2
    end
  end

  class Form < TestForm
    feature Coercion

    property :released_at, type: DRY_TYPES_CONSTANT::DateTime

    property :hit do
      property :length, type: DRY_TYPES_INT_CONSTANT
      property :good,   type: DRY_TYPES_CONSTANT::Bool
    end

    property :band do
      property :label do
        property :value, type: Irreversible
      end
    end
  end

  subject do
    Form.new(album)
  end

  let(:album) do
    OpenStruct.new(
      released_at: "31/03/1981",
      hit: OpenStruct.new(length: "312"),
      band: Band.new(OpenStruct.new(value: "9999.99"))
    )
  end

  # it { subject.released_at.must_be_kind_of DateTime }
  it { subject.released_at.must_equal "31/03/1981" } # NO coercion in setup.
  it { subject.hit.length.must_equal "312" }
  it { subject.band.label.value.must_equal "9999.99" }

  let(:params) do
    {
      released_at: "30/03/1981",
      hit: {length: "312"},
      band: {label: {value: "9999.99"}}
    }
  end

  # validate
  describe "#validate" do
    before { subject.validate(params) }

    it { subject.released_at.must_equal DateTime.parse("30/03/1981") }
    it { subject.hit.length.must_equal 312 }
    it { assert_nil subject.hit.good }
    it { subject.band.label.value.must_equal "9999.999999.99" } # coercion happened once.
  end

  # save
end
