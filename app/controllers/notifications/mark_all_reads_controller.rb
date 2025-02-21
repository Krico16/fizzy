class Notifications::MarkAllReadsController < ApplicationController
  def create
    Current.user.notifications.unread.read_all

    set_page_and_extract_portion_from Current.user.notifications.read.ordered if request.format.turbo_stream?

    Turbo::StreamsChannel.broadcast_update_to(
      [ Current.user, :notifications ],
      target: "notifications",
      html: ""
    )

    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end
end
