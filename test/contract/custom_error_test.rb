require "test_helper"

class CustomerErrorTest < MiniTest::Spec
  let(:key)            { :name }
  let(:error_text)     { "text2" }
  let(:starting_error) { [OpenStruct.new(errors: {title: ["text1"]})] }

  let(:custom_error) { Reform::Contract::CustomError.new(key, error_text, @results) }

  before { @results = starting_error }

  it "base class structure" do
    assert_equal custom_error.success?, false
    assert_equal custom_error.failure?, true
    assert_equal custom_error.errors, key => [error_text]
    assert_equal custom_error.messages, key => [error_text]
    assert_equal custom_error.hint, {}
  end

  describe "updates @results accordingly" do
    it "add new key" do
      custom_error

      assert_equal @results.size, 2
      errors = @results.map(&:errors)

      assert_equal errors[0], starting_error.first.errors
      assert_equal errors[1], custom_error.errors
    end

    describe "when key error already exists in @results" do
      let(:key) { :title }

      it "merge errors text" do
        custom_error

        assert_equal @results.size, 1

        assert_equal @results.first.errors.values, [%w[text1 text2]]
      end

      describe "add error text is already" do
        let(:error_text) { "text1" }

        it 'does not create duplicates' do
          custom_error

          assert_equal @results.size, 1

          assert_equal @results.first.errors.values, [%w[text1]]
        end
      end
    end
  end
end
