require "test_helper"

class Bubbles::PublishesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "create" do
    bubble = bubbles(:logo)
    bubble.drafted!

    assert_changes -> { bubble.reload.published? }, from: false, to: true do
      post bucket_bubble_publish_url(bubble.bucket, bubble)
    end

    assert_redirected_to bubble
  end
end
