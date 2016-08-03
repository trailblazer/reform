require "test_helper"
require "reform/form/dry"
require "reform/form/coercion"

class DryValidationDefaultGroupTest < Minitest::Spec
  Session = Struct.new(:username, :email, :password, :confirm_password, :starts_at, :active)

  class SessionForm < Reform::Form
    include Reform::Form::Dry
    include Coercion

    property :username
    property :email
    property :password
    property :confirm_password
    property :starts_at, type: Types::Form::DateTime
    property :active, type: Types::Form::Bool

    validation do
      required(:username).filled
      required(:email).filled
      required(:starts_at).filled(:date_time?)
      required(:active).filled(:bool?)
    end

    validation :another_block, error_message_format: :full do
      required(:confirm_password).filled
    end
  end

  let (:form) { SessionForm.new(Session.new) }

  # valid.
  it do
    form.validate(username: "Helloween",
                  email:    "yep",
                  starts_at: "01/01/2000 - 11:00",
                  active: "true",
                  confirm_password: 'pA55w0rd').must_equal true
    form.errors.messages.inspect.must_equal "{}"
  end

  it "invalid" do
    form.validate(username: "Helloween",
                  email:    "yep",
                  active: 'hello',
                  starts_at: "01/01/2000 - 11:00").must_equal false
    form.errors.messages.inspect.must_equal "{:active=>[\"must be boolean\"], :confirm_password=>[\"must be filled\"]}"
  end
end

class ValidationGroupsTest < MiniTest::Spec
  describe "basic validations" do
    Session = Struct.new(:username, :email, :password, :confirm_password)

    class SessionForm < Reform::Form
      include Reform::Form::Dry::Validations

      property :username
      property :email
      property :password
      property :confirm_password

      validation :default do
        required(:username).filled
        required(:email).filled
      end

      validation :email, if: :default do
        required(:email).filled(min_size?: 3)
      end

      validation :nested, if: :default do
        required(:password).filled(min_size?: 2)
      end

      validation :confirm, if: :default, after: :email do
        required(:confirm_password).filled(min_size?: 2)
      end
    end

    let (:form) { SessionForm.new(Session.new) }

    # valid.
    it do
      form.validate({ username: "Helloween",
                      email: "yep",
                      password: "99",
                      confirm_password: "99" }).must_equal true
      form.errors.messages.inspect.must_equal "{}"
    end

    # invalid.
    it do
      form.validate({}).must_equal false
      form.errors.messages.inspect.must_equal "{:username=>[\"must be filled\"], :email=>[\"must be filled\"]}"
    end

    # partially invalid.
    # 2nd group fails.
    it do
      form.validate(username: "Helloween", email: "yo", confirm_password:"9").must_equal false
      form.errors.messages.inspect.must_equal "{:email=>[\"size cannot be less than 3\"], :confirm_password=>[\"size cannot be less than 2\"], :password=>[\"must be filled\", \"size cannot be less than 2\"]}"
    end
    # 3rd group fails.
    it do
      form.validate(username: "Helloween", email: "yo!", confirm_password:"9").must_equal false
      form.errors.messages.inspect
      .must_equal "{:confirm_password=>[\"size cannot be less than 2\"], :password=>[\"must be filled\", \"size cannot be less than 2\"]}"
    end
    # 4th group with after: fails.
    it do
      form.validate(username: "Helloween", email: "yo!", password: "", confirm_password: "9").must_equal false
      form.errors.messages.inspect.must_equal "{:confirm_password=>[\"size cannot be less than 2\"], :password=>[\"must be filled\", \"size cannot be less than 2\"]}"
    end
  end

  describe "with custom schema class" do
    Session2 = Struct.new(:username, :email)

    class CustomSchema < Reform::Form::Dry::Schema
      configure do
        config.messages_file = 'test/fixtures/dry_error_messages.yml'

        def good_musical_taste?
          !form.nil?
        end
      end
    end

    class Session2Form < Reform::Form
      include Reform::Form::Dry::Validations

      property :username
      property :email

      validation schema: CustomSchema do
        required(:username).filled
        required(:email).filled(:good_musical_taste?)
      end
    end

    let (:form) { Session2Form.new(Session2.new) }

    # valid.
    it do
      form.validate({ username: "Helloween", email: "yep" }).must_equal true
      form.errors.messages.inspect.must_equal "{}"
    end

    # invalid.
    it do
      form.validate({}).must_equal false
      form.errors.messages.inspect.must_equal "{:username=>[\"must be filled\"], :email=>[\"must be filled\", \"you're a bad person\"]}"
    end
  end

  describe "Nested validations" do
    class AlbumForm < Reform::Form
      include Reform::Form::Dry::Validations

      property :title

      property :hit do
        property :title

        validation do
          required(:title).filled
        end
      end

      # we test this by embedding a validation block
      collection :songs do
        property :title

        validation do
          required(:title).filled
        end
      end

      # we test this one by running an each / schema dry-v check on the main block
      collection :producers do
        property :name
      end

      property :band do
        property :name
        property :label do
          property :name
        end
      end

      validation :default do
        configure do
          option :form
          config.messages_file = "test/fixtures/dry_error_messages.yml"
          # message need to be defined on fixtures/dry_error_messages
          # d-v expects you to define your custome messages on the .yml file
          def good_musical_taste?(value)
            value != 'Nickelback'
          end

          def form_access_validation?
            form.title == 'Reform'
          end
        end

        required(:title).filled(:good_musical_taste?, :form_access_validation?)

        required(:band).schema do
          required(:name).filled
          required(:label).schema do
            required(:name).filled
          end
        end

        required(:producers).each do
          schema do
            required(:name).filled
          end
        end

      end
    end

    let (:album) do
      OpenStruct.new(
        :title  => "Blackhawks Over Los Angeles",
        :hit    => song,
        :songs  => songs,
        :producers => [ OpenStruct.new(name: 'some name'), OpenStruct.new() ],
        :band => Struct.new(:name, :label).new("Epitaph", OpenStruct.new),
      )
    end
    let (:song)  { OpenStruct.new }
    let (:songs) { [ OpenStruct.new(:title => "Calling"),  OpenStruct.new] }
    let (:form)  { AlbumForm.new(album) }

    # correct #validate.
    it do
      result = form.validate(
        "title"  => "Reform",
        "songs"  => [
          {"title" => "Fallout"},
          {"title" => "", "composer" => {"name" => "Sting"}}
        ],
        "band"   => {"label" => {"name" => "Epitaph"}},
        "producers" => [{"name" => ''}, {"name" => ''}]
      )

      result.must_equal false
      form.errors.messages.inspect.must_equal %({:"producers.0.name"=>[\"must be filled\"], :"producers.1.name"=>[\"must be filled\"], {:"hit.title"=>["must be filled"], {:"songs.1.title"=>["must be filled"]}})
    end
  end

  # describe "same-named group" do
  #   class OverwritingForm < Reform::Form
  #     include Reform::Form::Dry::Validations

  #     property :username
  #     property :email

  #     validation :email do # FIX ME: is this working for other validator or just bugging here?
  #       key(:email, &:filled?) # it's not considered, overitten
  #     end

  #     validation :email do # just another group.
  #       key(:username, &:filled?)
  #     end
  #   end

  #   let (:form) { OverwritingForm.new(Session.new) }

  #   # valid.
  #   it do
  #     form.validate({username: "Helloween"}).must_equal true
  #   end

  #   # invalid.
  #   it "whoo" do
  #     form.validate({}).must_equal false
  #     form.errors.messages.inspect.must_equal "{:username=>[\"username can't be blank\"]}"
  #   end
  # end


  describe "inherit: true in same group" do
    class InheritSameGroupForm < Reform::Form
      include Reform::Form::Dry::Validations

      property :username
      property :email

      validation :email do
        required(:email).filled
      end

      validation :email, inherit: true do # extends the above.
        required(:username).filled
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
      form.errors.messages.inspect.must_equal "{:email=>[\"must be filled\"], :username=>[\"must be filled\"]}"
    end
  end


  describe "if: with lambda" do
    class IfWithLambdaForm < Reform::Form
      include Reform::Form::Dry::Validations # ::build_errors.

      property :username
      property :email
      property :password

      validation :email do
        required(:email).filled
      end

      # run this is :email group is true.
      validation :after_email, if: lambda { |results| results[:email]==true } do # extends the above.
        required(:username).filled
      end

      # block gets evaled in form instance context.
      validation :password, if: lambda { |results| email == "john@trb.org" } do
        required(:password).filled
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
      form.errors.messages.inspect.must_equal "{:username=>[\"must be filled\"]}"
    end
  end


  # Currenty dry-v don't support that option, it doesn't make sense
  #   I've talked to @solnic and he plans to add a "hint" feature to show
  #   more errors messages than only those that have failed.
  #
  # describe "multiple errors for property" do
  #   class MultipleErrorsForPropertyForm < Reform::Form
  #     include Reform::Form::Dry::Validations

  #     property :username

  #     validation :default do
  #       key(:username) do |username|
  #         username.filled? | (username.min_size?(2) & username.max_size?(3))
  #       end
  #     end
  #   end

  #   let (:form) { MultipleErrorsForPropertyForm.new(Session.new) }

  #   # valid.
  #   it do
  #     form.validate({username: ""}).must_equal false
  #     form.errors.messages.inspect.must_equal "{:username=>[\"username must be filled\", \"username is not proper size\"]}"
  #   end
  # end
end
