module NotificationsHelper
  def notification_title(notification)
    title = notification.bubble.title

    if notification.resource.is_a? Comment
      "RE: " + title
    else
      title
    end
  end

  def notification_body(notification)
    name = notification.creator.name

    case notification_event_action(notification)
    when "assigned" then "#{name} assigned to you"
    when "popped" then "Popped by by #{name}"
    when "published" then "Added by #{name}"
    else name
    end
  end

  def notification_tag(notification, &)
    link_to notification.resource, id: dom_id(notification), class: "notification border-radius",
      data: { turbo_frame: "_top" }, &
  end

  private
    def notification_event_action(notification)
      if notification_is_for_initial_assignement?(notification)
        "assigned"
      else
        notification.event.action
      end
    end

    def notification_is_for_initial_assignement?(notification)
      notification.event.action == "published" && notification.bubble.assigned_to?(notification.user)
    end
end
