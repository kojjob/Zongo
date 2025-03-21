class EventCommentsController < ApplicationController
  before_action :set_event_comment, only: %i[ show edit update destroy ]

  # GET /event_comments or /event_comments.json
  def index
    @event_comments = EventComment.all
  end

  # GET /event_comments/1 or /event_comments/1.json
  def show
  end

  # GET /event_comments/new
  def new
    @event_comment = EventComment.new
  end

  # GET /event_comments/1/edit
  def edit
  end

  # POST /event_comments or /event_comments.json
  def create
    @event_comment = EventComment.new(event_comment_params)

    respond_to do |format|
      if @event_comment.save
        format.html { redirect_to @event_comment, notice: "Event comment was successfully created." }
        format.json { render :show, status: :created, location: @event_comment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event_comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /event_comments/1 or /event_comments/1.json
  def update
    respond_to do |format|
      if @event_comment.update(event_comment_params)
        format.html { redirect_to @event_comment, notice: "Event comment was successfully updated." }
        format.json { render :show, status: :ok, location: @event_comment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event_comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /event_comments/1 or /event_comments/1.json
  def destroy
    @event_comment.destroy!

    respond_to do |format|
      format.html { redirect_to event_comments_path, status: :see_other, notice: "Event comment was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event_comment
      @event_comment = EventComment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def event_comment_params
      params.expect(event_comment: [ :event_id, :user_id, :parent_comment_id, :content, :is_hidden, :likes_count ])
    end
end
