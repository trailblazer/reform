require "test_helper"
require "reform/form/lotus"

class ActiveModelValidationTest < MiniTest::Spec
  Session = Struct.new(:username, :email, :password, :confirm_password)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  class SessionForm < Reform::Form
    include Reform::Form::ActiveModel::Validations


    property :username
    property :email
    property :password
    property :confirm_password

    validation :default do
      validates :username, presence: true
      validates :email, presence: true
    end

    validation :email, if: :default do
      # validate :email_ok? # FIXME: implement that.
      validates :email, length: {is: 3}
    end

    validation :nested, if: :default do
      validates :password, presence: true, length: {is: 1}
    end

    validation :confirm, if: :default, after: :email do
      validates :confirm_password, length: {is: 2}
    end
  end

  let (:form) { SessionForm.new(Session.new) }

  # valid.
  it do
    form.validate({username: "Helloween", email: "yep", password: "9", confirm_password:"dd"}).must_equal true
    form.errors.messages.inspect.must_equal "{}"
  end

  # invalid.
  it do
    form.validate({}).must_equal false
    form.errors.messages.inspect.must_equal "{:username=>[\"can't be blank\"], :email=>[\"can't be blank\"]}"
  end

  # partially invalid.
  # 2nd group fails.
  it do
    form.validate(username: "Helloween", email: "yo").must_equal false
    form.errors.messages.inspect.must_equal "{:email=>[\"is the wrong length (should be 3 characters)\"], :confirm_password=>[\"is the wrong length (should be 2 characters)\"], :password=>[\"can't be blank\", \"is the wrong length (should be 1 character)\"]}"
  end
  # 3rd group fails.
  it do
    form.validate(username: "Helloween", email: "yo!").must_equal false
    form.errors.messages.inspect.must_equal"{:confirm_password=>[\"is the wrong length (should be 2 characters)\"], :password=>[\"can't be blank\", \"is the wrong length (should be 1 character)\"]}"
  end
  # 4th group with after: fails.
  it do
    form.validate(username: "Helloween", email: "yo!", password: "1", confirm_password: "9").must_equal false
    form.errors.messages.inspect.must_equal "{:confirm_password=>[\"is the wrong length (should be 2 characters)\"]}"
  end


  describe "implicit :default group" do
    # implicit :default group.
    class LoginForm < Reform::Form
      include Reform::Form::ActiveModel::Validations


      property :username
      property :email
      property :password
      property :confirm_password

      validates :username, presence: true
      validates :email, presence: true
      validates :password, presence: true

      validation :after_default, if: :default do
        validates :confirm_password, presence: true
      end
    end

    let (:form) { LoginForm.new(Session.new) }

    # valid.
    it do
      form.validate({username: "Helloween", email: "yep", password: "9", confirm_password: 9}).must_equal true
      form.errors.messages.inspect.must_equal "{}"
    end

    # invalid.
    it do
      form.validate({password: 9}).must_equal false
      form.errors.messages.inspect.must_equal "{:username=>[\"can't be blank\"], :email=>[\"can't be blank\"]}"
    end

    # partially invalid.
    # 2nd group fails.
    it do
      form.validate(password: 9).must_equal false
      form.errors.messages.inspect.must_equal "{:username=>[\"can't be blank\"], :email=>[\"can't be blank\"]}"
    end
  end


  # describe "overwriting a group" do
  #   class OverwritingForm < Reform::Form
  #     include Reform::Form::ActiveModel::Validations

  #     property :username
  #     property :email

  #     validation :email do
  #       validates :email, presence: true # is not considered, but overwritten.
  #     end

  #     validation :email do # overwrites the above.
  #       validates :username, presence: true
  #     end
  #   end

  #   let (:form) { OverwritingForm.new(Session.new) }

  #   # valid.
  #   it do
  #     form.validate({username: "Helloween"}).must_equal true
  #   end

  #   # invalid.
  #   it do
  #     form.validate({}).must_equal false
  #     form.errors.messages.inspect.must_equal "{:username=>[\"username can't be blank\"]}"
  #   end
  # end


  describe "inherit: true in same group" do
    class InheritSameGroupForm < Reform::Form
      include Reform::Form::ActiveModel::Validations

      property :username
      property :email

      validation :email do
        validates :email, presence: true
      end

      validation :email, inherit: true do # extends the above.
        validates :username, presence: true
      end
    end

    let (:form) { InheritSameGroupForm.new(Session.new) }

    # valid.
    it do
      form.validate({username: "Helloween", email: 9}).must_equal true
    end

    # invalid.
    it do
      form.validate({}).must_equal false
      form.errors.messages.inspect.must_equal "{:email=>[\"can't be blank\"], :username=>[\"can't be blank\"]}"
    end
  end


  describe "if: with lambda" do
    class IfWithLambdaForm < Reform::Form
      include Reform::Form::ActiveModel::Validations

      property :username
      property :email
      property :password

      validation :email do
        validates :email, presence: true
      end

      # run this is :email group is true.
      validation :after_email, if: lambda { |results| results[:email]==true } do # extends the above.
        validates :username, presence: true
      end

      # block gets evaled in form instance context.
      validation :password, if: lambda { |results| email == "john@trb.org" } do
        validates :password, presence: true
      end
    end

    let (:form) { IfWithLambdaForm.new(Session.new) }

    # valid.
    it do
      form.validate({username: "Strung Out", email: 9}).must_equal true
    end

    # invalid.
    it do
      form.validate({email: 9}).must_equal false
      form.errors.messages.inspect.must_equal "{:username=>[\"can't be blank\"]}"
    end
  end


# TODO: describe "multiple errors for property" do

  describe "::validate" do
    class ValidateForm < Reform::Form
      include Reform::Form::ActiveModel::Validations

      property :username
      validates :username, presence: true
      validate :username_ok?#, context: :entity

      def username_ok?#(value)
        errors.add(:username, "not ok") if username == "yo"
      end
    end

    let (:form) { ValidateForm.new(Session.new) }

    # invalid.
    it do
      form.validate({username: "yo"}).must_equal false
      form.errors.messages.inspect.must_equal "{:username=>[\"not ok\"]}"
    end

    # valid.
    it do
      form.validate({username: "not yo"}).must_equal true
      form.errors.empty?.must_equal true
    end
  end
end