class EventMediaController < ApplicationController
  before_action :set_event_medium, only: %i[ show edit update destroy ]

  # GET /event_media or /event_media.json
  def index
    @event_media = EventMedium.all
  end

  # GET /event_media/1 or /event_media/1.json
  def show
  end

  # GET /event_media/new
  def new
    @event_medium = EventMedium.new
  end

  # GET /event_media/1/edit
  def edit
  end

  # POST /event_media or /event_media.json
  def create
    @event_medium = EventMedium.new(event_medium_params)

    respond_to do |format|
      if @event_medium.save
        format.html { redirect_to @event_medium, notice: "Event medium was successfully created." }
        format.json { render :show, status: :created, location: @event_medium }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event_medium.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /event_media/1 or /event_media/1.json
  def update
    respond_to do |format|
      if @event_medium.update(event_medium_params)
        format.html { redirect_to @event_medium, notice: "Event medium was successfully updated." }
        format.json { render :show, status: :ok, location: @event_medium }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event_medium.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /event_media/1 or /event_media/1.json
  def destroy
    event = @event_medium.event
    @event_medium.destroy!

    respond_to do |format|
      format.html { redirect_to edit_event_path(event), status: :see_other, notice: "Image was successfully removed." }
      format.json { head :no_content }
    end
  end

  # POST /event_media/1/set_as_featured
  def set_as_featured
    event = @event_medium.event

    # First, unset all other images as featured
    event.event_media.update_all(is_featured: false)

    # Then set this one as featured
    @event_medium.update(is_featured: true)

    redirect_to edit_event_path(event), notice: "Featured image has been updated."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event_medium
      @event_medium = EventMedium.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def event_medium_params
      params.require(:event_medium).permit(:event_id, :user_id, :media_type, :title, :description, :is_featured, :display_order)
    end
end
