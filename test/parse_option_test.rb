require "test_helper"

class ParseOptionTest < MiniTest::Spec
  Comment = Struct.new(:content, :user)
  User    = Struct.new(:name)

  class CommentForm < TestForm
    property :content
    property :user, parse: false
  end

  let(:current_user) { User.new("Peter") }
  let(:form) { CommentForm.new(Comment.new, user: current_user) }

  it do
    assert_equal form.user, current_user

    lorem = "Lorem ipsum dolor sit amet..."
    form.validate("content" => lorem, "user" => "not the current user")

    assert_equal form.content, lorem
    assert_equal form.user, current_user
  end

  describe "using ':parse' option doesn't override other ':deserialize' options" do
    class ArticleCommentForm < TestForm
      property :content
      property :article, deserializer: {instance: "Instance"}
      property :user, parse: false, deserializer: {instance: "Instance"}
    end

    it do
      assert_equal ArticleCommentForm.definitions.get(:user)[:deserializer][:writeable], false
      assert_equal ArticleCommentForm.definitions.get(:user)[:deserializer][:instance], "Instance"

      assert ArticleCommentForm.definitions.get(:article)[:deserializer][:writeable]
      assert_equal ArticleCommentForm.definitions.get(:article)[:deserializer][:instance], "Instance"
    end
  end
end
