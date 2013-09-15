class AlbumsController < ActionController::Base
  def new
    album = Album.new(:songs => [Song.new, Song.new])
    @form = AlbumForm.new(album)
  end

  def create
    album = Album.new(songs: [Song.new, Song.new])
    @form = AlbumForm.new(album)

    if @form.validate(params["album"])
      @form.save
      redirect_to album_path(album)
    else
      render :new
    end
  end
end
