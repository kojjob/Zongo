module Admin
  class EventsController < BaseController
    before_action :set_event, only: [:show, :edit, :update, :destroy, :feature, :unfeature, :approve, :reject]

    def index
      @events = Event.all.order(created_at: :desc)

      # Filter by status if provided
      if params[:status].present?
        case params[:status]
        when "upcoming"
          @events = @events.where("start_time > ?", Time.current)
        when "ongoing"
          @events = @events.where("start_time <= ? AND end_time >= ?", Time.current, Time.current)
        when "past"
          @events = @events.where("end_time < ?", Time.current)
        when "featured"
          @events = @events.where(featured: true)
        end
      end

      # Filter by organizer if provided
      if params[:organizer_id].present?
        @events = @events.where(organizer_id: params[:organizer_id])
      end

      # Filter by search term if provided
      if params[:search].present?
        @events = @events.where("title LIKE ? OR description LIKE ?",
                               "%#{params[:search]}%",
                               "%#{params[:search]}%")
      end

      # Paginate results
      @pagy, @events = pagy(@events, items: 10)
    end

    def show
      # Load event attendees
      @attendees = @event.attendees.order(created_at: :desc).limit(10)

      # Load event comments
      @comments = @event.event_comments.order(created_at: :desc).limit(10)

      # Load event media
      @media = @event.event_media.order(created_at: :desc)
    end

    def new
      @event = Event.new
    end

    def create
      @event = Event.new(event_params)
      @event.organizer = current_user unless params[:event][:organizer_id].present?

      if @event.save
        redirect_to admin_event_path(@event), notice: "Event was successfully created."
      else
        render :new
      end
    end

    def edit
    end

    def update
      if @event.update(event_params)
        redirect_to admin_event_path(@event), notice: "Event was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      if @event.destroy
        redirect_to admin_events_path, notice: "Event was successfully deleted."
      else
        redirect_to admin_event_path(@event), alert: "Failed to delete event."
      end
    end

    def feature
      if @event.update(is_featured: true)
        redirect_to admin_event_path(@event), notice: "Event has been featured."
      else
        redirect_to admin_event_path(@event), alert: "Failed to feature event."
      end
    end

    def unfeature
      if @event.update(is_featured: false)
        redirect_to admin_event_path(@event), notice: "Event has been unfeatured."
      else
        redirect_to admin_event_path(@event), alert: "Failed to unfeature event."
      end
    end

    def approve
      if @event.update(is_approved: true, approved_at: Time.current)
        redirect_to admin_event_path(@event), notice: "Event has been approved."
      else
        redirect_to admin_event_path(@event), alert: "Failed to approve event."
      end
    end

    def reject
      if @event.update(is_approved: false, approved_at: nil)
        redirect_to admin_event_path(@event), notice: "Event has been rejected."
      else
        redirect_to admin_event_path(@event), alert: "Failed to reject event."
      end
    end

    private

    def set_event
      # Try to find by slug first, then by ID
      @event = Event.find_by(slug: params[:id]) || Event.find(params[:id])
    end

    def event_params
      params.require(:event).permit(
        :title, :description, :start_time, :end_time, :location, :venue_id,
        :organizer_id, :capacity, :registration_deadline, :is_featured, :is_approved,
        :banner_image, :registration_url, :price, :currency, :is_free, :is_online,
        :online_url, :contact_email, :contact_phone, :published, :category_id
      )
    end
  end
end
