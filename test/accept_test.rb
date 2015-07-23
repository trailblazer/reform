require "test_helper"
require "reform/form/validation/accept_validator"

class AcceptValidatorTest < MiniTest::Spec
  class SongForm < Reform::Form
    property :terms, virtual: true
    validates :terms, accept: true
  end

  it do
    form = SongForm.new(Song.new)
    form.validate("terms" => false).must_equal false
    form.errors.to_s.must_equal "{:terms=>[\"must be accepted\"]}"
  end
end

class AcceptValidatorWithCustomValueTest < MiniTest::Spec
  class SongForm < Reform::Form
    property :terms, virtual: true
    validates :terms, accept: { accepted: "moo" }
  end

  it do
    form = SongForm.new(Song.new)
    form.validate("terms" => "moo").must_equal true
  end
end

class AcceptValidatorWithCustomValuesTest < MiniTest::Spec
  class SongForm < Reform::Form
    property :terms, virtual: true
    validates :terms, accept: { accepted: ["OK", 42] }
  end

  it do
    form = SongForm.new(Song.new)
    form.validate("terms" => "OK").must_equal true
  end

  it do
    form = SongForm.new(Song.new)
    form.validate("terms" => 42).must_equal true
  end
end
