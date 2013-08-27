class MusicianController < ActionController::Base
  def index
    render :text => Artist.find(:all)
  end
end
