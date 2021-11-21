require "test_helper"

class DesignTest < Minitest::Spec
  # 1. Decorate
  # 2. Deserialize
  # 3. Validate
  # 4. Persist/sync
  # 5. Present


  # 3. Validate
  it "what" do
    Album = Struct.new(:title, :songs)
    Song = Struct.new(:title, :band, :album_id)
    Band = Struct.new(:name)

    song = Song.new("Apocalypse soon", Band.new("")) # Could be done by Decorate()
    # assuming Validate() already happened

    song_form = Class.new(Reform::Form) do
      feature Reform::Form::Dry

      property :title
      property :band do # DISCUSS: polymorphic
        property :name

        validation do
          params do
            required(:name).filled
          end
        end
      end

      validation do
        params do
          required(:title).filled
          required(:album_id).filled

          # required(:band).schema do
          #   required(:name).filled
          # end
        end
      end
    end


# at this point, the form is fully populated from Decorate and from Deserialize
# title: "Apocalypse soon"
# bands:
#   type:rock-band
#     name: "..."
#   type:punk-band

song_form_instance = song_form.new(song)

# this happens during Deserialize()
song_form_instance.instance_variable_set(:@deserialized_values, {title: song_form_instance.title} )# FIXME: no nesting here, yet.
song_form_instance.band.instance_variable_set(:@deserialized_values, {name: song_form_instance.band.name})

# Goal is to decouple the actual validation process from a) the to-be-validated-data source and b) ?
  # {form} is the value container. {form} is schema provider, {form} is also needed as an exec_context for validations

  # {#validate!} grabs {deserialized_values} from {values_object}
    result = Reform::Contract::Validate.validate!("nil", form: song_form_instance, validation_groups: song_form.validation_groups,

      values_object: song_form_instance,
      )

    pp result

    result.errors[:title].inspect.must_equal %{[]}
    result.errors[:album_id].inspect.must_equal %{["is missing"]}

  end
end
