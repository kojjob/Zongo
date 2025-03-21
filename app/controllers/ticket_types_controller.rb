class TicketTypesController < ApplicationController
  before_action :set_ticket_type, only: %i[ show edit update destroy ]

  # GET /ticket_types or /ticket_types.json
  def index
    @ticket_types = TicketType.all
  end

  # GET /ticket_types/1 or /ticket_types/1.json
  def show
  end

  # GET /ticket_types/new
  def new
    @ticket_type = TicketType.new
  end

  # GET /ticket_types/1/edit
  def edit
  end

  # POST /ticket_types or /ticket_types.json
  def create
    @ticket_type = TicketType.new(ticket_type_params)

    respond_to do |format|
      if @ticket_type.save
        format.html { redirect_to @ticket_type, notice: "Ticket type was successfully created." }
        format.json { render :show, status: :created, location: @ticket_type }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ticket_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ticket_types/1 or /ticket_types/1.json
  def update
    respond_to do |format|
      if @ticket_type.update(ticket_type_params)
        format.html { redirect_to @ticket_type, notice: "Ticket type was successfully updated." }
        format.json { render :show, status: :ok, location: @ticket_type }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ticket_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ticket_types/1 or /ticket_types/1.json
  def destroy
    @ticket_type.destroy!

    respond_to do |format|
      format.html { redirect_to ticket_types_path, status: :see_other, notice: "Ticket type was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ticket_type
      @ticket_type = TicketType.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def ticket_type_params
      params.expect(ticket_type: [ :event_id, :name, :description, :price, :quantity, :sales_start_time, :sales_end_time, :sold_count, :max_per_user, :transferable ])
    end
end
