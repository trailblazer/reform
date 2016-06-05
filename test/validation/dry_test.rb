# require "test_helper"
# require "reform/form/dry"

# class BlaTest < MiniTest::Spec
#   class CartForm < Reform::Form
#     include Reform::Form::Dry::Validations

#     property :user_id

#     collection :variants do
#       property :id
#     end


#     validation :default do
#       key(:user_id).required

#       key(:variants).schema do
#         each do
#           key(:id).required
#         end
#       end

#       configure do
#         config.messages_file = 'test/validation/errors.yml'

#         option :form
#         # message need to be defined on fixtures/dry_error_messages
#         # d-v expects you to define your custome messages on the .yml file


#         def form_access_validation?(value)
#           raise value.inspect
#           form.title == 'Reform'
#         end
#       end

#       rule(form_present: [:form]) do |form|
#         form.user_id == "hallo"
#       end
#     end
#   end

#   it do
#     cart = Struct.new(:user_id, :variants).new(1, [Struct.new(:id).new])

#     form = CartForm.new(cart)
#     form.validate(user_id: 2, variants: [{id: 3}])
#     puts form.errors.inspect
#   end
# end


# # current_id: BlaTest
# # cart: {
# #   carts: {
# #     products: [{current_id}]
# #   }

# # }
