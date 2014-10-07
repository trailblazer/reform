require 'test_helper'

require 'test_helper'
require 'reform/twin'

class TwinTest < MiniTest::Spec
  class SongForm < Reform::Form
    class Twin < Disposable::Twin
      property :title
      option :is_online # TODO: this should make it read-only in reform!
    end

    include Reform::Twin
    twin Twin
  end

  let (:model) { OpenStruct.new(title: "Kenny") }

  let (:form) { SongForm.new(model, is_online: true) }

  it { form.title.must_equal "Kenny" }
  it { form.is_online.must_equal true }
end
