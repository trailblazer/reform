require "test_helper"
require "reform/form/coercion"
require "disposable/twin/property/hash"

class CoercionTest < BaseTest
  class Irreversible
    def self.call(value)
      value * 2
    end
  end

  class Form < TestForm
    feature Coercion
    include Disposable::Twin::Property::Hash

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

    property :metadata, field: :hash do
      property :publication_settings do
        property :featured, type: DRY_TYPES_CONSTANT::Bool
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
      band: Band.new(OpenStruct.new(value: "9999.99")),
      metadata: {}
    )
  end

  # it { subject.released_at.must_be_kind_of DateTime }
  it { _(subject.released_at).must_equal "31/03/1981" } # NO coercion in setup.
  it { _(subject.hit.length).must_equal "312" }
  it { _(subject.band.label.value).must_equal "9999.99" }

  let(:params) do
    {
      released_at: "30/03/1981",
      hit: {
        length: "312",
        good: "0",
      },
      band: {
        label: {
          value: "9999.99"
        }
      },
      metadata: {
        publication_settings: {
          featured: "0"
        }
      }
    }
  end

  # validate
  describe "#validate" do
    before { subject.validate(params) }

    it { _(subject.released_at).must_equal DateTime.parse("30/03/1981") }
    it { _(subject.hit.length).must_equal 312 }
    it { _(subject.hit.good).must_equal false }
    it { _(subject.band.label.value).must_equal "9999.999999.99" } # coercion happened once.
    it { _(subject.metadata.publication_settings.featured).must_equal false }
  end

  # sync
  describe "#sync" do
    before do
      _(subject.validate(params)).must_equal true
      subject.sync
    end

    it { _(album.released_at).must_equal DateTime.parse("30/03/1981") }
    it { _(album.hit.length).must_equal 312 }
    it { _(album.hit.good).must_equal false }
    it { assert_nil album.metadata[:publication_settings] }
    it { _(album.metadata["publication_settings"]["featured"]).must_equal false }
  end
end
