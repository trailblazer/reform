require "test_helper"
require "reform/form/dry"
require "reform/form/coercion"
#---
# one "nested" Schema per form.
class DryValidationErrorsAPITest < Minitest::Spec
  Album  = Struct.new(:title, :artist, :songs)
  Song   = Struct.new(:title)
  Artist = Struct.new(:email, :label)
  Label  = Struct.new(:location)

  class AlbumForm < TestForm
    property :title

    validation do
      params do
        required(:title).filled(min_size?: 2)
      end
    end

    property :artist do
      property :email

      validation do
        params { required(:email).filled }
      end

      property :label do
        property :location

        validation do
          params { required(:location).filled }
        end
      end
    end

    # note the validation block is *in* the collection block, per item, so to speak.
    collection :songs do
      property :title

      validation do
        config.messages.load_paths << "test/fixtures/dry_new_api_error_messages.yml"

        params { required(:title).filled }
      end
    end
  end

  let(:form) { AlbumForm.new(Album.new(nil, Artist.new(nil, Label.new), [Song.new(nil), Song.new(nil)])) }

  it "everything wrong" do
    result = form.(title: nil, artist: {email: ""}, songs: [{title: "Clams have feelings too"}, {title: ""}])

    _(result.success?).must_equal false

    _(form.errors.messages).must_equal(title: ["must be filled", "size cannot be less than 2"], "artist.email": ["must be filled"], "artist.label.location": ["must be filled"], "songs.title": ["must be filled"])
    _(form.artist.errors.messages).must_equal(email: ["must be filled"], "label.location": ["must be filled"])
    _(form.artist.label.errors.messages).must_equal(location: ["must be filled"])
    _(form.songs[0].errors.messages).must_equal({})
    _(form.songs[1].errors.messages).must_equal(title: ["must be filled"])

    # #errors[]
    _(form.errors[:nonsense]).must_equal []
    _(form.errors[:title]).must_equal ["must be filled", "size cannot be less than 2"]
    _(form.artist.errors[:email]).must_equal ["must be filled"]
    _(form.artist.label.errors[:location]).must_equal ["must be filled"]
    _(form.songs[0].errors[:title]).must_equal []
    _(form.songs[1].errors[:title]).must_equal ["must be filled"]

    # #to_result
    _(form.to_result.errors).must_equal(title: ["must be filled"])
    _(form.to_result.messages).must_equal(title: ["must be filled", "size cannot be less than 2"])
    _(form.to_result.hints).must_equal(title: ["size cannot be less than 2"])
    _(form.artist.to_result.errors).must_equal(email: ["must be filled"])
    _(form.artist.to_result.messages).must_equal(email: ["must be filled"])
    _(form.artist.to_result.hints).must_equal({})
    _(form.artist.label.to_result.errors).must_equal(location: ["must be filled"])
    _(form.artist.label.to_result.messages).must_equal(location: ["must be filled"])
    _(form.artist.label.to_result.hints).must_equal({})
    _(form.songs[0].to_result.errors).must_equal({})
    _(form.songs[0].to_result.messages).must_equal({})
    _(form.songs[0].to_result.hints).must_equal({})
    _(form.songs[1].to_result.errors).must_equal(title: ["must be filled"])
    _(form.songs[1].to_result.messages).must_equal(title: ["must be filled"])
    _(form.songs[1].to_result.hints).must_equal({})
    _(form.songs[1].to_result.errors(locale: :de)).must_equal(title: ["muss abgefüllt sein"])
    # seems like dry-v when calling Dry::Schema::Result#messages locale option is ignored
    # started a topic in their forum https://discourse.dry-rb.org/t/dry-result-messages-ignore-locale-option/910
    # form.songs[1].to_result.messages(locale: :de).must_equal(title: ["muss abgefüllt sein"])
    _(form.songs[1].to_result.hints(locale: :de)).must_equal({})
  end

  it "only nested property is invalid." do
    result = form.(title: "Black Star", artist: {email: ""})

    _(result.success?).must_equal false

    # errors.messages
    _(form.errors.messages).must_equal("artist.email": ["must be filled"], "artist.label.location": ["must be filled"], "songs.title": ["must be filled"])
    _(form.artist.errors.messages).must_equal(email: ["must be filled"], "label.location": ["must be filled"])
    _(form.artist.label.errors.messages).must_equal(location: ["must be filled"])
  end

  it "nested collection invalid" do
    result = form.(title: "Black Star", artist: {email: "uhm", label: {location: "Hannover"}}, songs: [{title: ""}])

    _(result.success?).must_equal false
    _(form.errors.messages).must_equal("songs.title": ["must be filled"])
  end

  #---
  #- validation .each
  class CollectionExternalValidationsForm < TestForm
    collection :songs do
      property :title
    end

    validation do
      params do
        required(:songs).each do
          schema do
            required(:title).filled
          end
        end
      end
    end
  end

  it do
    form = CollectionExternalValidationsForm.new(Album.new(nil, nil, [Song.new, Song.new]))
    form.validate(songs: [{title: "Liar"}, {title: ""}])

    _(form.errors.messages).must_equal("songs.title": ["must be filled"])
    _(form.songs[0].errors.messages).must_equal({})
    _(form.songs[1].errors.messages).must_equal(title: ["must be filled"])
  end
end

class DryValidationExplicitSchemaTest < Minitest::Spec
  Session = Struct.new(:name, :email)
  SessionContract = Dry::Validation.Contract do
    params do
      required(:name).filled
      required(:email).filled
    end
  end

  class SessionForm < TestForm
    include Coercion

    property :name
    property :email

    validation contract: SessionContract
  end

  let(:form) { SessionForm.new(Session.new) }

  # valid.
  it do
    _(form.validate(name: "Helloween", email: "yep")).must_equal true
    _(form.errors.messages.inspect).must_equal "{}"
  end

  it "invalid" do
    _(form.validate(name: "", email: "yep")).must_equal false
    _(form.errors.messages.inspect).must_equal "{:name=>[\"must be filled\"]}"
  end
end

class DryValidationDefaultGroupTest < Minitest::Spec
  Session = Struct.new(:username, :email, :password, :confirm_password, :starts_at, :active, :color)

  class SessionForm < TestForm
    include Coercion

    property :username
    property :email
    property :password
    property :confirm_password
    property :starts_at, type: DRY_TYPES_CONSTANT::DateTime
    property :active, type: DRY_TYPES_CONSTANT::Bool
    property :color

    validation do
      params do
        required(:username).filled
        required(:email).filled
        required(:starts_at).filled(:date_time?)
        required(:active).filled(:bool?)
      end
    end

    validation name: :another_block do
      params { required(:confirm_password).filled }
    end

    validation name: :dynamic_args do
      option :form
      params { optional(:color) }
      rule(:color) do
        if value
          key.failure("must be one of: #{form.colors}") unless form.colors.include? value
        end
      end
    end

    def colors
      %(red orange green)
    end
  end

  let(:form) { SessionForm.new(Session.new) }

  # valid.
  it do
    assert form.validate(
      username: "Helloween",
      email:    "yep",
      starts_at: "01/01/2000 - 11:00",
      active: "true",
      confirm_password: "pA55w0rd"
    )
    assert form.active
    assert_equal "{}", form.errors.messages.inspect
  end

  it "invalid" do
    _(form.validate(
      username: "Helloween",
      email:    "yep",
      active: "1",
      starts_at: "01/01/2000 - 11:00",
      color: "purple"
    )).must_equal false
    _(form.active).must_equal true
    _(form.errors.messages.inspect).must_equal "{:confirm_password=>[\"must be filled\"], :color=>[\"must be one of: red orange green\"]}"
  end
end

class ValidationGroupsTest < MiniTest::Spec
  describe "basic validations" do
    Session = Struct.new(:username, :email, :password, :confirm_password, :special_class)
    SomeClass = Struct.new(:id)

    class SessionForm < TestForm
      property :username
      property :email
      property :password
      property :confirm_password
      property :special_class

      validation do
        params do
          required(:username).filled
          required(:email).filled
          required(:special_class).filled(type?: SomeClass)
        end
      end

      validation name: :email, if: :default do
        params { required(:email).filled(min_size?: 3) }
      end

      validation name: :password, if: :email do
        params { required(:password).filled(min_size?: 2) }
      end

      validation name: :confirm, if: :default, after: :email do
        params { required(:confirm_password).filled(min_size?: 2) }
      end
    end

    let(:form) { SessionForm.new(Session.new) }

    # valid.
    it do
      _(form.validate(username: "Helloween",
                    special_class: SomeClass.new(id: 15),
                    email: "yep",
                    password: "99",
                    confirm_password: "99")).must_equal true
      _(form.errors.messages.inspect).must_equal "{}"
    end

    # invalid.
    it do
      _(form.validate({})).must_equal false
      _(form.errors.messages).must_equal({username: ["must be filled"], email: ["must be filled"], special_class: ["must be filled", "must be ValidationGroupsTest::SomeClass"]})
    end

    # partially invalid.
    # 2nd group fails.
    it do
      _(form.validate(username: "Helloween", email: "yo", confirm_password: "9", special_class: SomeClass.new(id: 15))).must_equal false
      _(form.errors.messages.inspect).must_equal "{:email=>[\"size cannot be less than 3\"], :confirm_password=>[\"size cannot be less than 2\"]}"
    end
    # 3rd group fails.
    it do
      _(form.validate(username: "Helloween", email: "yo!", confirm_password: "9", special_class: SomeClass.new(id: 15))).must_equal false
      _(form.errors.messages.inspect)
          .must_equal "{:confirm_password=>[\"size cannot be less than 2\"], :password=>[\"must be filled\", \"size cannot be less than 2\"]}"
    end
    # 4th group with after: fails.
    it do
      _(form.validate(username: "Helloween", email: "yo!", password: "1", confirm_password: "9", special_class: SomeClass.new(id: 15))).must_equal false
      _(form.errors.messages.inspect).must_equal "{:confirm_password=>[\"size cannot be less than 2\"], :password=>[\"size cannot be less than 2\"]}"
    end
  end

  class ValidationWithOptionsTest < MiniTest::Spec
    describe "basic validations" do
      Session = Struct.new(:username)
      class SessionForm < TestForm
        property :username

        validation name: :default, with: {user: OpenStruct.new(name: "Nick")} do
          option :user
          params do
            required(:username).filled
          end
          rule(:username) do
            key.failure("must be equal to #{user.name}") unless user.name == value
          end
        end
      end

      let(:form) { SessionForm.new(Session.new) }

      # valid.
      it do
        _(form.validate(username: "Nick")).must_equal true
        _(form.errors.messages.inspect).must_equal "{}"
      end

      # invalid.
      it do
        _(form.validate(username: "Fred")).must_equal false
        _(form.errors.messages.inspect).must_equal "{:username=>[\"must be equal to Nick\"]}"
      end
    end
  end

  #---
  describe "with custom schema" do
    Session2 = Struct.new(:username, :email, :password)

    MyContract = Dry::Schema.Params do
      config.messages.load_paths << "test/fixtures/dry_error_messages.yml"

      required(:password).filled(min_size?: 6)
    end

    class Session2Form < TestForm
      property :username
      property :email
      property :password

      validation contract: MyContract do
        params do
          required(:username).filled
          required(:email).filled
        end

        rule(:email) do
          key.failure(:good_musical_taste?) unless value.is_a? String
        end
      end
    end

    let(:form) { Session2Form.new(Session2.new) }

    # valid.
    it do
      skip "waiting dry-v to add this as feature https://github.com/dry-rb/dry-schema/issues/33"
      _(form.validate(username: "Helloween", email: "yep", password: "extrasafe")).must_equal true
      _(form.errors.messages.inspect).must_equal "{}"
    end

    # invalid.
    it do
      skip "waiting dry-v to add this as feature https://github.com/dry-rb/dry-schema/issues/33"
      _(form.validate({})).must_equal false
      _(form.errors.messages).must_equal(password: ["must be filled", "size cannot be less than 6"], username: ["must be filled"], email: ["must be filled", "you're a bad person"])
    end

    it do
      skip "waiting dry-v to add this as feature https://github.com/dry-rb/dry-schema/issues/33"
      _(form.validate(email: 1)).must_equal false
      _(form.errors.messages.inspect).must_equal "{:password=>[\"must be filled\", \"size cannot be less than 6\"], :username=>[\"must be filled\"], :email=>[\"you're a bad person\"]}"
    end
  end

  describe "MIXED nested validations" do
    class AlbumForm < TestForm
      property :title

      property :hit do
        property :title

        validation do
          params { required(:title).filled }
        end
      end

      collection :songs do
        property :title

        validation do
          params { required(:title).filled }
        end
      end

      # we test this one by running an each / schema dry-v check on the main block
      collection :producers do
        property :name
      end

      property :band do
        property :name
        property :label do
          property :location
        end
      end

      validation do
        config.messages.load_paths << "test/fixtures/dry_new_api_error_messages.yml"
        params do
          required(:title).filled
          required(:band).hash do
            required(:name).filled
            required(:label).hash do
              required(:location).filled
            end
          end

          required(:producers).each do
            hash { required(:name).filled }
          end
        end

        rule(:title) do
          key.failure(:good_musical_taste?) unless value != "Nickelback"
        end
      end
    end

    let(:album) do
      OpenStruct.new(
        hit: OpenStruct.new,
        songs: [OpenStruct.new, OpenStruct.new],
        band: Struct.new(:name, :label).new("", OpenStruct.new),
        producers: [OpenStruct.new, OpenStruct.new, OpenStruct.new],
      )
    end

    let(:form) { AlbumForm.new(album) }

    it "maps errors to form objects correctly" do
      result = form.validate(
        "title"  => "Nickelback",
        "songs"  => [{"title" => ""}, {"title" => ""}],
        "band"   => {"size" => "", "label" => {"location" => ""}},
        "producers" => [{"name" => ""}, {"name" => "something lovely"}]
      )

      _(result).must_equal false
      # from nested validation
      _(form.errors.messages).must_equal(title: ["you're a bad person"], "hit.title": ["must be filled"], "songs.title": ["must be filled"], "producers.name": ["must be filled"], "band.name": ["must be filled"], "band.label.location": ["must be filled"])

      # songs have their own validation.
      _(form.songs[0].errors.messages).must_equal(title: ["must be filled"])
      # hit got its own validation group.
      _(form.hit.errors.messages).must_equal(title: ["must be filled"])

      _(form.band.label.errors.messages).must_equal(location: ["must be filled"])
      _(form.band.errors.messages).must_equal(name: ["must be filled"], "label.location": ["must be filled"])
      _(form.producers[0].errors.messages).must_equal(name: ["must be filled"])

      # TODO: use the same form structure as the top one and do the same test against messages, errors and hints.
      _(form.producers[0].to_result.errors).must_equal(name: ["must be filled"])
      _(form.producers[0].to_result.messages).must_equal(name: ["must be filled"])
      _(form.producers[0].to_result.hints).must_equal({})
    end

    # FIXME: fix the "must be filled error"

    it "renders full messages correctly" do
      result = form.validate(
        "title"  => "",
        "songs"  => [{"title" => ""}, {"title" => ""}],
        "band"   => {"size" => "", "label" => {"name" => ""}},
        "producers" => [{"name" => ""}, {"name" => ""}, {"name" => "something lovely"}]
      )

      _(result).must_equal false
      _(form.band.errors.full_messages).must_equal ["Name must be filled", "Label Location must be filled"]
      _(form.band.label.errors.full_messages).must_equal ["Location must be filled"]
      _(form.producers.first.errors.full_messages).must_equal ["Name must be filled"]
      _(form.errors.full_messages).must_equal ["Title must be filled", "Hit Title must be filled", "Songs Title must be filled", "Producers Name must be filled", "Band Name must be filled", "Band Label Location must be filled"]
    end

    describe "only 1 nested validation" do
      class AlbumFormWith1NestedVal < TestForm
        property :title
        property :band do
          property :name
          property :label do
            property :location
          end
        end

        validation do
          config.messages.load_paths << "test/fixtures/dry_new_api_error_messages.yml"

          params do
            required(:title).filled

            required(:band).schema do
              required(:name).filled
              required(:label).schema do
                required(:location).filled
              end
            end
          end
        end
      end

      let(:form) { AlbumFormWith1NestedVal.new(album) }

      it "allows to access dry's result semantics per nested form" do
        form.validate(
          "title" => "",
          "songs" => [{"title" => ""}, {"title" => ""}],
          "band" => {"size" => "", "label" => {"name" => ""}},
          "producers" => [{"name" => ""}, {"name" => ""}, {"name" => "something lovely"}]
        )

        _(form.to_result.errors).must_equal(title: ["must be filled"])
        _(form.band.to_result.errors).must_equal(name: ["must be filled"])
        _(form.band.label.to_result.errors).must_equal(location: ["must be filled"])

        # with locale: "de"
        _(form.to_result.errors(locale: :de)).must_equal(title: ["muss abgefüllt sein"])
        _(form.band.to_result.errors(locale: :de)).must_equal(name: ["muss abgefüllt sein"])
        _(form.band.label.to_result.errors(locale: :de)).must_equal(location: ["muss abgefüllt sein"])
      end
    end
  end

  # describe "same-named group" do
  #   class OverwritingForm < TestForm
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

  #   let(:form) { OverwritingForm.new(Session.new) }

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
    class InheritSameGroupForm < TestForm
      property :username
      property :email
      property :full_name, virtual: true

      validation name: :username do
        params do
          required(:username).filled
          required(:full_name).filled
        end
      end

      validation name: :username, inherit: true do # extends the above.
        params do
          optional(:username).maybe(:string)
          required(:email).filled
        end
      end
    end

    let(:form) { InheritSameGroupForm.new(Session.new) }

    # valid.
    it do
      skip "waiting dry-v to add this as feature https://github.com/dry-rb/dry-schema/issues/33"
      _(form.validate(email: 9)).must_equal true
    end

    # invalid.
    it do
      skip "waiting dry-v to add this as feature https://github.com/dry-rb/dry-schema/issues/33"
      _(form.validate({})).must_equal false
      _(form.errors.messages).must_equal email: ["must be filled"], full_name: ["must be filled"]
    end
  end

  describe "if: with lambda" do
    class IfWithLambdaForm < TestForm
      property :username
      property :email
      property :password

      validation name: :email do
        params { required(:email).filled }
      end

      # run this is :email group is true.
      validation name: :after_email, if: ->(results) { results[:email].success? } do # extends the above.
        params { required(:username).filled }
      end

      # block gets evaled in form instance context.
      validation name: :password, if: ->(results) { email == "john@trb.org" } do
        params { required(:password).filled }
      end
    end

    let(:form) { IfWithLambdaForm.new(Session.new) }

    # valid.
    it do
      _(form.validate(username: "Strung Out", email: 9)).must_equal true
    end

    # invalid.
    it do
      _(form.validate(email: 9)).must_equal false
      _(form.errors.messages.inspect).must_equal "{:username=>[\"must be filled\"]}"
    end
  end

  class NestedSchemaValidationTest < MiniTest::Spec
    AddressSchema = Dry::Schema.Params do
      required(:company).filled(:int?)
    end

    class OrderForm < TestForm
      property :delivery_address do
        property :company
      end

      validation do
        params { required(:delivery_address).schema(AddressSchema) }
      end
    end

    let(:company) { Struct.new(:company) }
    let(:order) { Struct.new(:delivery_address) }
    let(:form)  { OrderForm.new(order.new(company.new)) }

    it "has company error" do
      _(form.validate(delivery_address: {company: "not int"})).must_equal false
      _(form.errors.messages).must_equal(:"delivery_address.company" => ["must be an integer"])
    end
  end

  class NestedSchemaValidationWithFormTest < MiniTest::Spec
    class CompanyForm < TestForm
      property :company

      validation do
        params { required(:company).filled(:int?) }
      end
    end

    class OrderFormWithForm < TestForm
      property :delivery_address, form: CompanyForm
    end

    let(:company) { Struct.new(:company) }
    let(:order)   { Struct.new(:delivery_address) }
    let(:form)    { OrderFormWithForm.new(order.new(company.new)) }

    it "has company error" do
      _(form.validate(delivery_address: {company: "not int"})).must_equal false
      _(form.errors.messages).must_equal(:"delivery_address.company" => ["must be an integer"])
    end
  end

  class CollectionPropertyWithCustomRuleTest < MiniTest::Spec
    Artist = Struct.new(:first_name, :last_name)
    Song   = Struct.new(:title, :enabled)
    Album  = Struct.new(:title, :songs, :artist)

    class AlbumForm < TestForm
      property :title

      collection :songs, virtual: true, populate_if_empty: Song do
        property :title
        property :enabled

        validation do
          params { required(:title).filled }
        end
      end

      property :artist, populate_if_empty: Artist do
        property :first_name
        property :last_name
      end

      validation do
        config.messages.load_paths << "test/fixtures/dry_new_api_error_messages.yml"

        params do
          required(:songs).filled
          required(:artist).filled
        end

        rule(:songs) do
          key.failure(:a_song?) unless value.any? { |el| el && el[:enabled] }
        end

        rule(:artist) do
          key.failure(:with_last_name?) unless value[:last_name]
        end
      end
    end

    it "validates fails and shows the correct errors" do
      form = AlbumForm.new(Album.new(nil, [], nil))
      _(form.validate(
        "songs" => [
          {"title" => "One", "enabled" => false},
          {"title" => nil, "enabled" => false},
          {"title" => "Three", "enabled" => false}
        ],
        "artist" => {"last_name" => nil}
      )).must_equal false
      _(form.songs.size).must_equal 3

      _(form.errors.messages).must_equal(
        :songs => ["must have at least one enabled song"],
        :artist => ["must have last name"],
        :"songs.title" => ["must be filled"]
      )
    end
  end

  class DryVWithSchemaAndParams < MiniTest::Spec
    Foo = Struct.new(:age)

    class ParamsForm < TestForm
      property :age

      validation do
        params { required(:age).value(:integer) }

        rule(:age) { key.failure("value exceeded") if value > 999 }
      end
    end

    class SchemaForm < TestForm
      property :age

      validation do
        schema { required(:age).value(:integer) }

        rule(:age) { key.failure("value exceeded") if value > 999 }
      end
    end

    it "using params" do
      model = Foo.new
      form = ParamsForm.new(model)
      _(form.validate(age: "99")).must_equal true
      form.sync
      _(model.age).must_equal "99"

      form = ParamsForm.new(Foo.new)
      _(form.validate(age: "1000")).must_equal false
      _(form.errors.messages).must_equal age: ["value exceeded"]
    end

    it "using schema" do
      model = Foo.new
      form = SchemaForm.new(model)
      _(form.validate(age: "99")).must_equal false
      _(form.validate(age: 99)).must_equal true
      form.sync
      _(model.age).must_equal 99

      form = SchemaForm.new(Foo.new)
      _(form.validate(age: 1000)).must_equal false
      _(form.errors.messages).must_equal age: ["value exceeded"]
    end
  end

  # Currenty dry-v don't support that option, it doesn't make sense
  #   I've talked to @solnic and he plans to add a "hint" feature to show
  #   more errors messages than only those that have failed.
  #
  # describe "multiple errors for property" do
  #   class MultipleErrorsForPropertyForm < TestForm
  #     include Reform::Form::Dry::Validations

  #     property :username

  #     validation :default do
  #       key(:username) do |username|
  #         username.filled? | (username.min_size?(2) & username.max_size?(3))
  #       end
  #     end
  #   end

  #   let(:form) { MultipleErrorsForPropertyForm.new(Session.new) }

  #   # valid.
  #   it do
  #     form.validate({username: ""}).must_equal false
  #     form.errors.messages.inspect.must_equal "{:username=>[\"username must be filled\", \"username is not proper size\"]}"
  #   end
  # end
end
