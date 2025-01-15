require "test_helper"

class Notifier::PublishedTest < ActiveSupport::TestCase
  test "creates a notification for each recipient" do
    notifications = Notifier.for(events(:logo_published)).generate

    assert_equal users(:kevin, :jz).sort, notifications.map(&:user).sort
  end

  test "links to the bubble" do
    Notifier.for(events(:logo_published)).generate

    assert_equal bubbles(:logo), Notification.last.resource
  end
end
