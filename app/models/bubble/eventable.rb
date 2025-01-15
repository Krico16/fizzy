module Bubble::Eventable
  extend ActiveSupport::Concern

  private
    def track_event(action, creator: Current.user, **particulars)
      event = find_or_capture_event_summary.events.create! action: action, creator: creator, particulars: particulars
      event.generate_notifications_later
    end

    def find_or_capture_event_summary
      transaction do
        messages.last&.event_summary || capture(EventSummary.new).event_summary
      end
    end
end
