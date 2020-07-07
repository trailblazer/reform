require "test_helper"

class ReadableTest < MiniTest::Spec
  Credentials = Struct.new(:password)

  class PasswordForm < TestForm
    property :password, readable: false
  end

  let(:cred) { Credentials.new }
  let(:form) { PasswordForm.new(cred) }

  it {
    assert_nil form.password # password not read.

    form.validate("password" => "123")

    assert_equal form.password, "123"

    form.sync
    assert_equal cred.password, "123" # password written.

    hash = {}
    form.save do |nested|
      hash = nested
    end

    assert_equal hash, "password" => "123"
  }
end
