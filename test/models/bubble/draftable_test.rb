require "test_helper"

class Bubble::DraftableTest < ActiveSupport::TestCase
  test "bubbles are only visible to the creator by default" do
    bubble = buckets(:writebook).bubbles.create! creator: users(:kevin), title: "Drafted Bubble"

    assert bubble.drafted?
    assert_includes Bubble.published_or_drafted_by(users(:kevin)), bubble
    assert_not_includes Bubble.published_or_drafted_by(users(:jz)), bubble
  end

  test "bubbles are visible to everyone when published" do
    bubble = buckets(:writebook).bubbles.create! creator: users(:kevin), title: "Drafted Bubble"
    bubble.published!

    assert bubble.published?
    assert_includes Bubble.published_or_drafted_by(users(:kevin)), bubble
    assert_includes Bubble.published_or_drafted_by(users(:jz)), bubble
  end
end
