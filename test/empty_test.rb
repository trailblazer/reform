require 'test_helper'


class DeprecatedVirtualTest < MiniTest::Spec # TODO: remove me in 2.0.
  Location = Struct.new(:country)

  class LocationForm < Reform::Form
    property :country, virtual: true # this becomes readonly: true
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

class DeprecatedEmptyTest < MiniTest::Spec # don't read, don't write
  Credentials = Struct.new(:password)

  class PasswordForm < Reform::Form
    property :password
    property :password_confirmation, empty: true
  end

  let (:cred) { Credentials.new }
  let (:form) { PasswordForm.new(cred) }

  it {
    form.validate("password" => "123", "password_confirmation" => "321")

    form.password.must_equal "123"
    form.password_confirmation.must_equal "321" # this is still readable in the UI.

    form.sync
    cred.password.must_equal "123"

    hash = {}
    form.save do |nested|
      hash = nested
    end

    hash.must_equal("password"=> "123", "password_confirmation" => "321")
  }
end