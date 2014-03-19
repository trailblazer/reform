class AlbumForm < Reform::Form # FIXME: sub forms don't inherit FBM.

  model :album

  property :title

  collection :songs do
    property :title
    validates :title, presence: true
  end

  validates :title, presence: true

  # TODO: Remove this. It should be handled by Reform::Form::ActiveRecord now
  def save
    super
    model.save
  end
end
