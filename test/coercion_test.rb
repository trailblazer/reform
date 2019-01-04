require "test_helper"
require "reform/form/coercion"
require "disposable/twin/property/hash"

class CoercionTest < BaseTest
  class Irreversible
    def self.call(value)
      value*2
    end
  end

  class Form < TestForm
    feature Coercion
    include Disposable::Twin::Property::Hash

    property :released_at, type: Types::Form::DateTime

    property :hit do
      property :length, type: Types::Form::Int
      property :good,   type: Types::Form::Bool
    end

    property :band do
      property :label do
        property :value, type: Irreversible
      end
    end

    property :metadata, field: :hash do
      property :publication_settings do
        property :featured, type: Types::Params::Bool
      end
    end
  end

  subject do
    Form.new(album)
  end

  let (:album) {
    OpenStruct.new(
      released_at: "31/03/1981",
      hit: OpenStruct.new(length: "312"),
      band: Band.new(OpenStruct.new(value: "9999.99")),
      metadata: {},
    )
  }

  # it { subject.released_at.must_be_kind_of DateTime }
  it { subject.released_at.must_equal "31/03/1981" } # NO coercion in setup.
  it { subject.hit.length.must_equal "312" }
  it { subject.band.label.value.must_equal "9999.99" }


  let (:params) {
    {
      released_at: "30/03/1981",
      hit: {
        length: "312",
        good: '0',
      },
      band: {
        label: {
          value: "9999.99"
        }
      },
      metadata: {
        publication_settings: {
          featured: '0',
        }
      },
    }
  }


  # validate
  describe "#validate" do
    before { subject.validate(params) }

    it { subject.released_at.must_equal DateTime.parse("30/03/1981") }
    it { subject.hit.length.must_equal 312 }
    it { subject.hit.good.must_equal false }
    it { subject.band.label.value.must_equal "9999.999999.99" } # coercion happened once.
    it { subject.metadata.publication_settings.featured.must_equal false }
  end

  # save
end
