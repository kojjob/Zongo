class EventFavoritesController < ApplicationController
  before_action :set_event_favorite, only: %i[ show edit update destroy ]

  # GET /event_favorites or /event_favorites.json
  def index
    @event_favorites = EventFavorite.all
  end

  # GET /event_favorites/1 or /event_favorites/1.json
  def show
  end

  # GET /event_favorites/new
  def new
    @event_favorite = EventFavorite.new
  end

  # GET /event_favorites/1/edit
  def edit
  end

  # POST /event_favorites or /event_favorites.json
  def create
    @event_favorite = EventFavorite.new(event_favorite_params)

    respond_to do |format|
      if @event_favorite.save
        format.html { redirect_to @event_favorite, notice: "Event favorite was successfully created." }
        format.json { render :show, status: :created, location: @event_favorite }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event_favorite.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /event_favorites/1 or /event_favorites/1.json
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

  # DELETE /event_favorites/1 or /event_favorites/1.json
  def destroy
    @event_favorite.destroy!

    respond_to do |format|
      format.html { redirect_to event_favorites_path, status: :see_other, notice: "Event favorite was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event_favorite
      @event_favorite = EventFavorite.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def event_favorite_params
      params.expect(event_favorite: [ :event_id, :user_id ])
    end
end
