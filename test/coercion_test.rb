require "test_helper"
require "reform/form/coercion"

class CoercionTest < BaseTest
  class Irreversible < Virtus::Attribute
    def coerce(value)
      value*2
    end
  end

  class Form < Reform::Form
    feature Coercion

    property :released_at, :type => DateTime

    property :hit do
      property :length, :type => Integer
      property :good,   :type => Virtus::Attribute::Boolean
    end

    property :band do
      property :label do
        property :value, :type => Irreversible
      end
    end
  end

  subject do
    Form.new(album)
  end

  let (:album) {
    OpenStruct.new(
      :released_at => "31/03/1981",
      :hit         => OpenStruct.new(:length => "312"),
      :band        => Band.new(OpenStruct.new(:value => "9999.99"))
    )
  }

  # it { subject.released_at.must_be_kind_of DateTime }
  it { subject.released_at.must_equal "31/03/1981" } # NO coercion in setup.
  it { subject.hit.length.must_equal "312" }
  it { subject.band.label.value.must_equal "9999.99" }


  let (:params) {
    {
      :released_at => "30/03/1981",
      :hit         => {:length => "312"},
      :band        => {:label => {:value => "9999.99"}}
    }
  }


  # validate
  describe "#validate" do
    before { subject.validate(params) }

    it { subject.released_at.must_equal DateTime.parse("30/03/1981") }
    it { subject.hit.length.must_equal 312 }
    it { subject.hit.good.must_equal nil }
    it { subject.band.label.value.must_equal "9999.999999.99" } # coercion happened once.
  end

  # save
end