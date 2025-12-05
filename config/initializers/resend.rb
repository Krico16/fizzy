# Register custom Resend delivery method for ActionMailer
require_relative "../../lib/resend_delivery_method"

Rails.logger.info("🔧 Registering Resend delivery method for ActionMailer")
ActionMailer::Base.add_delivery_method :resend, ResendDeliveryMethod
Rails.logger.info("✅ Resend delivery method registered successfully")
