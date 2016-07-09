require 'test_helper'

class ParseOptionTest < MiniTest::Spec
  Comment = Struct.new(:content, :user)
  User    = Struct.new(:name)

  class CommentForm < Reform::Form
    property :content
    property :user, parse: false
  end

  let (:current_user) { User.new("Peter") }
  let (:form) { CommentForm.new(Comment.new, user: current_user) }

  it do
    form.user.must_equal current_user

    lorem = "Lorem ipsum dolor sit amet..."
    form.validate("content" => lorem, "user" => "not the current user")

    form.content.must_equal lorem
    form.user.must_equal current_user
  end

  describe "using ':parse' option doesn't override other ':deserialize' options" do
    class ArticleCommentForm < Reform::Form
      property :content
      property :article, deserializer: { instance: "Instance" }
      property :user, parse: false, deserializer: { instance: "Instance" }
    end

    it do
      ArticleCommentForm.definitions.get(:user)[:deserializer][:writeable].must_equal false
      ArticleCommentForm.definitions.get(:user)[:deserializer][:instance].must_equal "Instance"

      ArticleCommentForm.definitions.get(:article)[:deserializer][:writeable].must_equal true
      ArticleCommentForm.definitions.get(:article)[:deserializer][:instance].must_equal "Instance"
    end
  end
end
