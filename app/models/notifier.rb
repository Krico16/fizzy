class Notifier
  attr_reader :event

  delegate :creator, to: :event

  class << self
    def for(event)
      "Notifier::#{event.action.classify}".safe_constantize&.new(event)
    end
  end

  def generate
    if should_notify?
      recipients.map do |recipient|
        Notification.create! user: recipient, event: event, bubble: bubble, resource: resource
      end
    end
  end

  private
    def initialize(event)
      @event = event
    end

    def should_notify?
      bubble.published?
    end

    def recipients
      bubble.bucket.users.without(creator)
    end

    def resource
      bubble
    end

    def bubble
      event.summary.message.bubble
    end
end
