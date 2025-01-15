module Bubble::Draftable
  extend ActiveSupport::Concern

  included do
    enum :status, %w[ drafted published ].index_by(&:itself)

    scope :published_or_drafted_by, ->(user) { where(status: :published).or(where(creator: user)) }
  end

  def publish
    transaction do
      published!
      track_event :published
    end
  end
end
