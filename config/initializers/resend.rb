# Register custom Resend delivery method for ActionMailer
require_relative "../../lib/resend_delivery_method"

ActionMailer::Base.add_delivery_method :resend, ResendDeliveryMethod

# Log registration after Rails is fully initialized
Rails.application.config.after_initialize do
  Rails.logger.info("🔧 Resend delivery method registered for ActionMailer")
  Rails.logger.info("📧 Current delivery method: #{ActionMailer::Base.delivery_method}")
end
