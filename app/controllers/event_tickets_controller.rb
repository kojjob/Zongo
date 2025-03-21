class EventTicketsController < ApplicationController
  before_action :set_event_ticket, only: %i[ show edit update destroy ]

  # GET /event_tickets or /event_tickets.json
  def index
    @event_tickets = EventTicket.all
  end

  # GET /event_tickets/1 or /event_tickets/1.json
  def show
  end

  # GET /event_tickets/new
  def new
    @event_ticket = EventTicket.new
  end

  # GET /event_tickets/1/edit
  def edit
  end

  # POST /event_tickets or /event_tickets.json
  def create
    @event_ticket = EventTicket.new(event_ticket_params)

    respond_to do |format|
      if @event_ticket.save
        format.html { redirect_to @event_ticket, notice: "Event ticket was successfully created." }
        format.json { render :show, status: :created, location: @event_ticket }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event_ticket.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /event_tickets/1 or /event_tickets/1.json
  def update
    respond_to do |format|
      if @event_ticket.update(event_ticket_params)
        format.html { redirect_to @event_ticket, notice: "Event ticket was successfully updated." }
        format.json { render :show, status: :ok, location: @event_ticket }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event_ticket.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /event_tickets/1 or /event_tickets/1.json
  def destroy
    @event_ticket.destroy!

    respond_to do |format|
      format.html { redirect_to event_tickets_path, status: :see_other, notice: "Event ticket was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event_ticket
      @event_ticket = EventTicket.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def event_ticket_params
      params.expect(event_ticket: [ :user_id, :event_id, :ticket_type_id, :attendance_id, :ticket_code, :status, :amount, :used_at, :refunded_at, :payment_reference, :transaction_id ])
    end
end
