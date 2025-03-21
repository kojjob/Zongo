class EventFavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event_favorite, only: %i[ show edit update destroy ]

  # GET /event_favorites
  def index
    @event_favorites = current_user.event_favorites.includes(:event).order(created_at: :desc)
  end

  # GET /event_favorites/1
  def show
  end

  # GET /event_favorites/new
  def new
    @event_favorite = EventFavorite.new
  end

  # GET /event_favorites/1/edit
  def edit
  end

  # POST /event_favorites
  def create
    @event = Event.find(params[:event_id])
    @event_favorite = current_user.event_favorites.find_or_initialize_by(event: @event)

    respond_to do |format|
      if @event_favorite.save
        format.html { redirect_back fallback_location: @event, notice: "Event added to favorites." }
        format.json { render json: { status: "success", favorited: true, count: @event.reload.favorites_count } }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("favorite_button_#{@event.id}", partial: "events/favorite_button", locals: { event: @event }) }
      else
        format.html { redirect_back fallback_location: @event, alert: "Error adding event to favorites." }
        format.json { render json: { status: "error", errors: @event_favorite.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /event_favorites/1
  def update
    respond_to do |format|
      if @event_favorite.update(event_favorite_params)
        format.html { redirect_to @event_favorite, notice: "Event favorite was successfully updated." }
        format.json { render :show, status: :ok, location: @event_favorite }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event_favorite.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /event_favorites/1 or toggle by event_id
  def destroy
    if params[:id].present?
      # Delete by ID
      @event_favorite.destroy!
      event = @event_favorite.event
    elsif params[:event_id].present?
      # Delete by event_id and current_user
      event = Event.find(params[:event_id])
      @event_favorite = current_user.event_favorites.find_by(event: event)
      @event_favorite&.destroy!
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: event_favorites_path, notice: "Removed from favorites." }
      format.json { render json: { status: "success", favorited: false, count: event.reload.favorites_count } }
      format.turbo_stream { render turbo_stream: turbo_stream.replace("favorite_button_#{event.id}", partial: "events/favorite_button", locals: { event: event }) }
    end
  end

  # POST /events/:event_id/toggle_favorite
  def toggle
    @event = Event.find(params[:event_id])
    @event_favorite = current_user.event_favorites.find_by(event: @event)

    if @event_favorite
      @event_favorite.destroy!
      favorited = false
    else
      @event_favorite = current_user.event_favorites.create!(event: @event)
      favorited = true
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: @event }
      format.json { render json: { status: "success", favorited: favorited, count: @event.reload.favorites_count } }
      format.turbo_stream { render turbo_stream: turbo_stream.replace("favorite_button_#{@event.id}", partial: "events/favorite_button", locals: { event: @event }) }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event_favorite
      @event_favorite = EventFavorite.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def event_favorite_params
      params.require(:event_favorite).permit(:event_id, :user_id)
    end
end
