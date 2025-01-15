class Bubbles::PublishesController < ApplicationController
  include BubbleScoped, BucketScoped

  def create
    @bubble.publish
    redirect_to @bubble
  end
end
