# Register custom Resend delivery method for ActionMailer
require_relative "../../lib/resend_delivery_method"

ActionMailer::Base.add_delivery_method :resend, ResendDeliveryMethod
