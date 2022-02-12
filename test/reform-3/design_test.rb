require "test_helper"

class DesignTest < Minitest::Spec
  # 1. Decorate
  # 2. Deserialize
  # 3. Validate
  # 4. Persist/sync
  # 5. Present

  # ROM Changeset
  # task = tasks.transaction do
  #   user = users.changeset(:create, name: 'Jane').commit

  #   new_task = tasks.changeset(:create, title: 'Task One').associate(user)

  #   new_task.commit
  # end


  # 3. Validate
  it "what" do
    Album = Struct.new(:title, :songs)
    Song = Struct.new(:title, :band, :album_id) do
      def save
        @persisted = true
      end
    end
    Band = Struct.new(:name) do
      def save
        @persisted = true
      end
    end

    song = Song.new("Apocalypse soon", band = Band.new("")) # Could be done by Decorate()
    # assuming Validate() already happened

    song_form = Class.new(Reform::Form) do
      feature Reform::Form::Dry

      property :title
      property :band do # DISCUSS: polymorphic
        property :name

        validation name: :FIXME, group_class: Reform::Form::Dry::Validations::Group do
          params do
            required(:name).filled
          end
        end
      end

      validation name: :FIXME, group_class: Reform::Form::Dry::Validations::Group do
        params do
          required(:title).filled
          required(:album_id).filled

          # required(:band).schema do
          #   required(:name).filled
          # end
        end
      end
    end

# hydrated = Reform::Form::Hydrate(input: song, schema: song_form.schema[:hydrate])


# at this point, the form is fully populated from Decorate and from Deserialize
# title: "Apocalypse soon"
# bands:
#   type:rock-band
#     name: "..."
#   type:punk-band

# song_form_instance = song_form.new#(song)

params = {title: "The Brews", band: {name: "NOFX"}}

populated_instance = Reform::Deserialize::DeserializedFields.new

# Deserialize/Hydrate an empty form just by iterating the schema, and for each nested form node, instantiate a form.
deserialized_form = Reform::Deserialize.deserialize(song_form, params, {}, populated_instance: populated_instance)


# assert_equal [:title, :band], deserialized_values.keys # {:band} is reference to a Twin
# assert twin.band, deserialized_values[:band][2] # test the "twin" part

assert_equal "The Brews", deserialized_form.title
assert_equal "The Brews", deserialized_form[:"title.value.read"]
assert_equal({:name=>"NOFX"}, deserialized_form[:"band.value.read"])
# assert_equal %{[:input, :populated_instance, :twin, :\"title.value.read\", :title, :\"band.value.read\", :band]}, ctx.keys.inspect
# assert_equal %{Apocalypse soon}, twin.title

# # FIXME
# assert_raises do
#   assert_equal %{Apocalypse soon}, song_form_instance.title

# end

# d,c,t = deserialized_values[:band]
assert_equal "NOFX", deserialized_form.band.name
assert_equal "NOFX", deserialized_form.band[:"name.value.read"]
# assert_equal %{[:populated_instance, :twin, :input, :\"name.value.read\", :name]}, c.keys.inspect
# assert_raises do
#   assert_equal "", song_form_instance.band.name
# end

# assert_equal %{{:title=>"The Brews", :band=>{:name=>"NOFX"}}}, deserialized_values.inspect


validated_form = Reform::Contract::Validate.run_validations(nil, twin: song_form_instance, deserialized_form: deserialized_form, validation_groups: song_form_instance.class.validation_groups)

# errors works
_(validated_form.success?).must_equal false
_(validated_form.errors[:title].inspect).must_equal %{[]}
_(validated_form.errors[:album_id].inspect).must_equal %{["is missing"]}

# accessors work
_(validated_form.title).must_equal "The Brews"
_(validated_form[:"title.value.read"]).must_equal "The Brews"

# nested errors work
_(validated_form.band.success?).must_equal true
_(validated_form.band.errors[:name].inspect).must_equal %{[]}
# nested accessors work
_(validated_form.band[:"name.value.read"].inspect).must_equal %{"NOFX"}


Reform::Form::Save(deserialized_form)

pp deserialized_form.instance_variable_get(:@form)

# fuck mutable state
_(song.inspect).must_equal %{#<struct DesignTest::Song title=\"The Brews\", band=#<struct DesignTest::Band name=\"NOFX\">, album_id=nil>}

# pp validated_form
raise


# errors
song_form_instance = song_form.new(song)



# this happens during Deserialize()
song_form_instance.instance_variable_set(:@deserialized_values, {title: song_form_instance.title} )# FIXME: no nesting here, yet.
song_form_instance.band.instance_variable_set(:@deserialized_values, {name: song_form_instance.band.name})

# strong interfaces between deserialization and validation, encapsulating the parsing process
# Goal is to decouple the actual validation process from a) the to-be-validated-data source and b) ?
  # {form} is the value container. {form} is schema provider, {form} is also needed as an exec_context for validations

  # {#validate!} grabs {deserialized_values} from {values_object}
    result = Reform::Contract::Validate.validate!("nil", form: song_form_instance, validation_groups: song_form.validation_groups,

      values_object: song_form_instance,
      )

    pp result

    result.errors[:title].inspect.must_equal %{[]}
    result.errors[:album_id].inspect.must_equal %{["is missing"]}


    # test blank "" validation
  song_form_instance = song_form.new(song)
  song_form_instance.instance_variable_set(:@deserialized_values, {title: ""} )
  result = Reform::Contract::Validate.validate!("nil", form: song_form_instance, validation_groups: song_form.validation_groups,

      values_object: song_form_instance,
      )

    # pp result

    result.errors[:title].inspect.must_equal %{["must be filled"]} # correct message for blank string.
    result.errors[:album_id].inspect.must_equal %{["is missing"]}

  end
end
