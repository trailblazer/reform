require 'test_helper'

class VirtualTest < MiniTest::Spec
  class CreditCardForm < Reform::Form
    property :credit_card_number, virtual: true # no read, no write, it's virtual.
  end

  let (:form) { CreditCardForm.new(Object.new) }

  it {
    form.validate("credit_card_number" => "123")

    form.credit_card_number.must_equal "123"  # this is still readable in the UI.

    form.sync

    hash = {}
    form.save do |nested|
      hash = nested
    end

    hash.must_equal("credit_card_number"=> "123")
  }
end