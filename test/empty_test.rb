require 'test_helper'

class EmptyAttributesTest < MiniTest::Spec
  Credentials = Struct.new(:password)

  class PasswordForm < Reform::Form
    property :password
    property :password_confirmation, :empty => true
  end

  let (:cred) { Credentials.new }
  let (:form) { PasswordForm.new(cred) }

  it {
    form.validate("password" => "123", "password_confirmation" => "321")

    form.password.must_equal "123"
    form.password_confirmation.must_equal "321"

    form.sync
    cred.password.must_equal "123"

    hash = {}
    form.save do |nested|
      hash = nested
    end

    hash.must_equal("password"=> "123", "password_confirmation" => "321")
  }
end