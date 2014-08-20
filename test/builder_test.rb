# require 'test_helper'

# class BuilderTest < MiniTest::Spec
#   it do
#     Builder.new.checkboxes(:settings, :hash => {"play" => true, "released" => false}).must_equal %{<input name="yo" type="hidden" value="unchecked_value" /><input id="object_name_method" name="yo" type="checkbox" value="checked_value" />
# <input name="yo" type="hidden" value="unchecked_value" /><input id="object_name_method" name="yo" type="checkbox" value="checked_value" />}
#   end
# end


# require 'action_view/helpers/capture_helper'
# require 'action_view/helpers/tag_helper'
# require 'action_view/helpers/url_helper'
# require 'action_view/helpers/sanitize_helper'
# require 'action_view/helpers/text_helper'
# require 'action_view/helpers/form_tag_helper'
# require 'action_view/helpers/form_helper'

# class Builder
#   include ActionView::Helpers::CaptureHelper
#   include ActionView::Helpers::FormHelper

#   # {name: value}
#   def checkboxes(name, options)
#     # get property form.to_a ? to_builder_hash or something like that
#     options[:hash].collect do |id, value|
#       ActionView::Helpers::InstanceTag.new(:object_name, :method, self).to_check_box_tag({:name => "yo"}, :checked_value, :unchecked_value)

#       # check_box_tag(id, value, checked = false, {})
#     end.join("\n")
#   end
# end