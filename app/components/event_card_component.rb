class EventCardComponent < ViewComponent::Base
  def initialize(event:, current_user: nil)
    @event = event
    @current_user = current_user
  end
end
