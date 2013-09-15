class AlbumsController < ActionController::Base
  def new
    album = Album.new(:songs => [Song.new, Song.new])
    @form = AlbumForm.new(album)
  end
end
