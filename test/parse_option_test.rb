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
    _(form.user).must_equal current_user

    lorem = "Lorem ipsum dolor sit amet..."
    form.validate("content" => lorem, "user" => "not the current user")

    _(form.content).must_equal lorem
    _(form.user).must_equal current_user
  end

  describe "using ':parse' option doesn't override other ':deserialize' options" do
    class ArticleCommentForm < TestForm
      property :content
      property :article, deserializer: {instance: "Instance"}
      property :user, parse: false, deserializer: {instance: "Instance"}
    end

    it do
      _(ArticleCommentForm.definitions.get(:user)[:deserializer][:writeable]).must_equal false
      _(ArticleCommentForm.definitions.get(:user)[:deserializer][:instance]).must_equal "Instance"

      _(ArticleCommentForm.definitions.get(:article)[:deserializer][:writeable]).must_equal true
      _(ArticleCommentForm.definitions.get(:article)[:deserializer][:instance]).must_equal "Instance"
    end
  end
end
