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
    @event_medium.destroy!

    respond_to do |format|
      format.html { redirect_to event_media_path, status: :see_other, notice: "Event medium was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event_medium
      @event_medium = EventMedium.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def event_medium_params
      params.expect(event_medium: [ :event_id, :user_id, :media_type, :title, :description, :is_featured, :display_order ])
    end
end
