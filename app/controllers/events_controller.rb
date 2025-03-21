class EventsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show, :toggle_favorite ]
  before_action :set_event, only: [ :show, :edit, :update, :destroy, :toggle_favorite ]

  # GET /events or /events.json
  def index
    @events = Event.all

    # Load hero banner if Setting model exists and the setting is available
    if defined?(Setting)
      begin
        @hero_banner_setting = Setting.find_by(key: "events_hero_banner")
        @hero_banner = @hero_banner_setting&.image if @hero_banner_setting&.image&.attached?
      rescue => e
        Rails.logger.error("Error loading hero banner: #{e.message}")
      end
    end

    # If no custom banner, try to get one from a featured event
    if @hero_banner.nil?
      @featured_event = Event.where(is_featured: true).order(created_at: :desc).first
    end
  end

  # GET /events/1 or /events/1.json
  def show
    # Track view count
    @event.increment_view_count! if @event.present?
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
  end

  # POST /events or /events.json
  def create
    @event = Event.new(event_params)

    respond_to do |format|
      if @event.save
        format.html { redirect_to @event, notice: "Event was successfully created." }
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/1 or /events/1.json
  def update
    respond_to do |format|
      if @event.update(event_params)
        format.html { redirect_to @event, notice: "Event was successfully updated." }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1 or /events/1.json
  def destroy
    @event.destroy!

    respond_to do |format|
      format.html { redirect_to events_path, status: :see_other, notice: "Event was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # POST /events/1/toggle_favorite
  def toggle_favorite
    if user_signed_in?
      @event_favorite = current_user.event_favorites.find_by(event: @event)

      if @event_favorite
        @event_favorite.destroy!
        favorited = false
      else
        @event_favorite = current_user.event_favorites.create!(event: @event)
        favorited = true
      end

      respond_to do |format|
        format.html { redirect_back fallback_location: event_path(@event), notice: favorited ? "Added to favorites" : "Removed from favorites" }
        format.json { render json: { status: "success", favorited: favorited, count: @event.reload.favorites_count } }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("favorite_button_#{@event.id}", partial: "events/favorite_button", locals: { event: @event }) }
      end
    else
      respond_to do |format|
        format.html { redirect_to new_user_session_path, alert: "Please sign in to favorite this event" }
        format.json { render json: { status: "error", message: "Authentication required" }, status: :unauthorized }
        format.turbo_stream { redirect_to new_user_session_path, alert: "Please sign in to favorite this event" }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.require(:event).permit(:title, :description, :short_description, :start_time, :end_time, :capacity, :status, :is_featured, :is_free, :is_private, :access_code, :slug, :organizer_id, :event_category_id, :venue_id, :recurrence_type, :recurrence_pattern, :parent_event_id, :favorites_count, :views_count, :custom_fields)
    end
end
