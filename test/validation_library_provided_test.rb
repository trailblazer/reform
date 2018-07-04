require "reform"
require "minitest/autorun"

class ValidationLibraryProvidedTest < MiniTest::Spec
  it "no validation library loaded" do
    assert_raises Reform::Validation::NoValidationLibraryError do
      class PersonForm < Reform::Form
        property :name

        validation do
          required(:name).maybe(:str?)
        end
      end
    end
  end
end
