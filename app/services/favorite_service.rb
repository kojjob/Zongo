class FavoriteService
  attr_reader :user
  
  def initialize(user)
    @user = user
  end
  
  def toggle_favorite(favoritable)
    return ServiceResult.error("User is required") unless user
    return ServiceResult.error("Cannot favorite nil object") unless favoritable
    
    begin
      # Try to use the favorites table
      favorite = user.favorites.find_by(favoritable: favoritable)
      
      if favorite
        favorite.destroy
        ServiceResult.success(favorited: false, favorite_count: count_favorites(favoritable))
      else
        user.favorites.create(favoritable: favoritable)
        ServiceResult.success(favorited: true, favorite_count: count_favorites(favoritable))
      end
    rescue ActiveRecord::StatementInvalid => e
      if e.message.include?('relation "favorites" does not exist')
        # Fallback to using event_favorites for Event objects
        if favoritable.is_a?(Event) && defined?(EventFavorite)
          event_favorite = EventFavorite.find_by(user_id: user.id, event_id: favoritable.id)
          
          if event_favorite
            event_favorite.destroy
            ServiceResult.success(favorited: false, favorite_count: count_favorites(favoritable))
          else
            EventFavorite.create(user_id: user.id, event_id: favoritable.id)
            ServiceResult.success(favorited: true, favorite_count: count_favorites(favoritable))
          end
        else
          ServiceResult.error("Favorites table doesn't exist yet.")
        end
      else
        ServiceResult.error("Error toggling favorite: #{e.message}")
      end
    rescue => e
      ServiceResult.error("Error toggling favorite: #{e.message}")
    end
  end
  
  private
  
  def count_favorites(favoritable)
    # Count favorites or event_favorites depending on what's available
    begin
      favoritable.favorites.count
    rescue ActiveRecord::StatementInvalid => e
      if e.message.include?('relation "favorites" does not exist') && favoritable.is_a?(Event) && defined?(EventFavorite)
        favoritable.event_favorites.count
      else
        0
      end
    rescue
      0
    end
  end
end

# Simple service result class
class ServiceResult
  attr_reader :success, :error, :data
  
  def initialize(success, error = nil, data = {})
    @success = success
    @error = error
    @data = data
  end
  
  def self.success(data = {})
    new(true, nil, data)
  end
  
  def self.error(message)
    new(false, message)
  end
  
  def success?
    @success
  end
end
