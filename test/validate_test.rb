require 'test_helper'

class ValidateTest < BaseTest
  describe "populated" do
    let (:params) {
      {
        "title" => "Best Of",
        "hit"   => {"title" => "Roxanne"},
        "songs" => [{"title" => "Fallout"}, {"title" => "Roxanne"}]
      }
    }

    subject { AlbumForm.new(Album.new(nil, Song.new, [Song.new, Song.new])) }

    before { subject.validate(params) }

    it { subject.title.must_equal "Best Of" }

    it { subject.hit.must_be_kind_of Reform::Form }
    it { subject.hit.title.must_equal "Roxanne" }

    it { subject.songs.must_be_kind_of Reform::Form::Forms }
    it { subject.songs.size.must_equal 2 }

    it { subject.songs[0].must_be_kind_of Reform::Form }
    it { subject.songs[0].title.must_equal "Fallout" }

    it { subject.songs[1].must_be_kind_of Reform::Form }
    it { subject.songs[1].title.must_equal "Roxanne" }
  end


  describe "setup with populator" do
    let (:form) {
      Class.new(Reform::Form) do
        property :hit, :populator => lambda { |fragment, args|
          puts "******************* #{fragment}"

          hit or self.hit = args.binding[:form].new(Song.new)
          # TODO: wrap into form/Forms automatically in :instance.
          # what happens with @model? we have to sync that as well.
        } do
          property :title
        end
      end
     }

    let (:params) {
      {
        "hit"   => {"title" => "Roxanne"},
        # "songs" => [{"title" => "Fallout"}, {"title" => "Roxanne"}]
      }
    }

    subject { form.new(Album.new) }

    before { subject.validate(params) }

    it( "xxx") { subject.hit.title.must_equal "Roxanne" }
  end
end

# #validate(params)
#  title=(params[:title])
#  song.validate(params[:song], errors)

# #sync (assumes that forms already have updated fields)
#   model.title=
#   song.sync