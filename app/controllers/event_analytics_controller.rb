class EventAnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event
  before_action :authorize_organizer!

  def show
    @total_views = @event.event_views.count
    @unique_viewers = @event.event_views.select(:ip_address).distinct.count
    @views_by_date = @event.event_views.where("created_at >= ?", 30.days.ago)
                          .group("DATE(created_at)")
                          .count
                          .transform_keys { |k| k.to_date.to_s }

    # Calculate conversion rate (views to attendees)
    @conversion_rate = @total_views.positive? ? (@event.attendances.count.to_f / @total_views * 100).round(2) : 0

    # Views today and yesterday for comparison
    @views_today = @event.event_views.today.count
    @views_yesterday = @event.event_views.yesterday.count
    @day_over_day_change = @views_yesterday.positive? ?
      ((@views_today.to_f - @views_yesterday) / @views_yesterday * 100).round(2) : 100

    # Device breakdown
    @device_breakdown = {}
    @event.event_views.find_each do |view|
      device = view.device_type
      @device_breakdown[device] ||= 0
      @device_breakdown[device] += 1
    end

    # Traffic sources
    @traffic_sources = {}
    @event.event_views.find_each do |view|
      source = view.source
      @traffic_sources[source] ||= 0
      @traffic_sources[source] += 1
    end

    # Popular hours (when people view the event)
    @popular_hours = @event.event_views
                          .group("EXTRACT(HOUR FROM created_at)::integer")
                          .count
                          .transform_keys(&:to_i)

    # Attendance stats
    @attendances_count = @event.attendances.count
    @attendance_by_date = @event.attendances.where("created_at >= ?", 30.days.ago)
                               .group("DATE(created_at)")
                               .count
                               .transform_keys { |k| k.to_date.to_s }

    # Capacity percentage
    @capacity_percentage = @event.capacity.present? && @event.capacity > 0 ?
                          (@event.attendances.count.to_f / @event.capacity * 100).round(2) : 0

    respond_to do |format|
      format.html
      format.json do
        render json: {
          total_views: @total_views,
          unique_viewers: @unique_viewers,
          views_by_date: @views_by_date,
          conversion_rate: @conversion_rate,
          device_breakdown: @device_breakdown,
          traffic_sources: @traffic_sources,
          popular_hours: @popular_hours,
          attendance_stats: {
            count: @attendance_count,
            by_date: @attendance_by_date,
            capacity_percentage: @capacity_percentage
          }
        }
      end
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def authorize_organizer!
    unless current_user == @event.organizer
      flash[:alert] = "You don't have permission to view analytics for this event."
      redirect_to @event
    end
  end
end
