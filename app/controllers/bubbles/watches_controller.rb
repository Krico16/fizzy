class Bubbles::WatchesController < ApplicationController
  include BubbleScoped

  def create
    @bubble.watch_by Current.user
    redirect_to bucket_bubble_watch_path(@bucket, @bubble)
  end

  def destroy
    @bubble.unwatch_by Current.user
    redirect_to bucket_bubble_watch_path(@bucket, @bubble)
  end
end
