class AlbumsController < ActionController::Base
  def new
    @album = Album.new(:songs => [Song.new, Song.new])
  end
end
