class Apps::FavoritesController < Apps::ApplicationController

    def index
        @articles = current_user.favorites_articles
    end
end