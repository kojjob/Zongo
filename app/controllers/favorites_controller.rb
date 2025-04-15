class FavoritesController < ApplicationController
  before_action :authenticate_user!

  # GET /favorites
  def index
    @favorite_events = current_user.favorite_events.includes(:category, :venue).order(start_time: :asc)
  end

  # POST /favorites
  def create
    @favoritable = find_favoritable

    if @favoritable
      result = FavoriteService.new(current_user).favorite(@favoritable)

      respond_to do |format|
        format.html do
          if result.success?
            redirect_back fallback_location: root_path, notice: "Added to favorites!"
          else
            redirect_back fallback_location: root_path, alert: result.error
          end
        end

        format.json do
          if result.success?
            render json: result.data
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        end
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, alert: "Item not found." }
        format.json { render json: { error: "Item not found" }, status: :not_found }
      end
    end
  end

  # DELETE /favorites/:id
  def destroy
    @favorite = current_user.favorites.find_by(id: params[:id])

    if @favorite
      @favorite.destroy
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, notice: "Removed from favorites." }
        format.json { render json: { success: true } }
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, alert: "Favorite not found." }
        format.json { render json: { error: "Favorite not found" }, status: :not_found }
      end
    end
  end

  private

  def find_favoritable
    params[:favoritable_type].constantize.find_by(id: params[:favoritable_id])
  rescue NameError
    nil
  end
end
