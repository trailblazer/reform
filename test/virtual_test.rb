require "test_helper"

class VirtualTest < MiniTest::Spec
  class CreditCardForm < TestForm
    property :credit_card_number, virtual: true # no read, no write, it's virtual.
    collection :transactions, virtual: true, populate_if_empty: OpenStruct do
      property :id
    end
  end

  let(:form) { CreditCardForm.new(Object.new) }

  it {
    form.validate(credit_card_number: "123", transactions: [id: 1])

    assert_equal form.credit_card_number, "123" # this is still readable in the UI.
    assert_equal form.transactions.first.id, 1 # this is still readable in the UI.

    form.sync

    hash = {}
    form.save do |nested|
      hash = nested
    end

    assert_equal hash, "credit_card_number" => "123", "transactions" => ["id" => 1]
  }
end

class VirtualAndDefaultTest < MiniTest::Spec
  class CreditCardForm < TestForm
    property :credit_card_number, virtual: true, default: "123" # no read, no write, it's virtual.
    collection :transactions, virtual: true, populate_if_empty: OpenStruct, default: [OpenStruct.new(id: 2)] do
      property :id
    end
  end

  def hash(form)
    hash = {}
    form.save do |nested|
      hash = nested
    end
    hash
  end

  let(:form) { CreditCardForm.new(Object.new) }

  it {
    form = CreditCardForm.new(Object.new)
    form.validate({})

    assert_equal hash(form), "credit_card_number" => "123", "transactions" => ["id" => 2]

    form = CreditCardForm.new(Object.new)
    form.validate(credit_card_number: "123", transactions: [id: 1])

    assert_equal form.credit_card_number,  "123" # this is still readable in the UI.
    assert_equal form.transactions.first.id,  1 # this is still readable in the UI.

    form.sync

    assert_equal hash(form), "credit_card_number" => "123", "transactions" => ["id" => 1]
  }
end
