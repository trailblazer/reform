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

    property :released_at, type: Types::Params::DateTime

    property :hit do
      property :length, type: Types::Params::Integer
      property :good,   type: Types::Params::Bool
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

  let(:album) do
    OpenStruct.new(
      released_at: "31/03/1981",
      hit: OpenStruct.new(length: "312"),
      band: Band.new(OpenStruct.new(value: "9999.99")),
      metadata: {}
    )
  end

  # it { subject.released_at.must_be_kind_of DateTime }
  it { assert_equal subject.released_at, "31/03/1981" } # NO coercion in setup.
  it { assert_equal subject.hit.length, "312" }
  it { assert_equal subject.band.label.value, "9999.99" }

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

    it { assert_equal subject.released_at, DateTime.parse("30/03/1981") }
    it { assert_equal subject.hit.length, 312 }
    it { assert_equal subject.hit.good, false }
    it { assert_equal subject.band.label.value, "9999.999999.99" } # coercion happened once.
    it { assert_equal subject.metadata.publication_settings.featured, false }
  end

  # sync
  describe "#sync" do
    before do
      assert subject.validate(params)
      subject.sync
    end

    it { assert_equal album.released_at, DateTime.parse("30/03/1981") }
    it { assert_equal album.hit.length, 312 }
    it { assert_equal album.hit.good, false }
    it { assert_nil album.metadata[:publication_settings] }
    it { assert_equal album.metadata["publication_settings"]["featured"], false }
  end
end
