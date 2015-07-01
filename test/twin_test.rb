require 'test_helper'

require 'test_helper'
require 'reform/twin'

# class TwinTest < MiniTest::Spec
#   class SongForm < Reform::Form
#     class Twin < Disposable::Twin
#       property :title
#       option :is_online # TODO: this should make it read-only in reform!
#     end

#     # include Reform::Twin
#     # twin Twin
#   end

#   let (:model) { OpenStruct.new(title: "Kenny") }

#   let (:form) { SongForm.new(model, is_online: true) }

#   it { form.title.must_equal "Kenny" }
#   it { form.is_online.must_equal true }
# end
class TwinTest < MiniTest::Spec
  Song = Struct.new(:name)

  class SongForm < Reform::Form
    property :name
    property :is_online, virtual: true
  end

  let (:form) { SongForm.new(Song.new("Kenny"), is_online: true) }

  it do
    form.name.must_equal "Kenny"
    form.is_online.must_equal true
  end
end