require "resend"

# Custom ActionMailer delivery method for Resend API
# This allows Rails to send emails through Resend instead of SMTP
class ResendDeliveryMethod
  attr_accessor :settings

  def initialize(settings = {})
    @settings = settings
    configure_resend
  end

  def deliver!(mail)
    configure_resend

    # Convert ActionMailer::Mail to Resend API format
    params = build_resend_params(mail)
    
    # Send via Resend API
    response = Resend::Emails.send(params)
    
    # Log success
    Rails.logger.info("Email sent via Resend API: #{response}")
    
    response
  rescue => e
    Rails.logger.error("Resend API error: #{e.message}")
    raise e if @settings[:raise_delivery_errors]
  end

  private
    def configure_resend
      Resend.api_key = @settings[:api_key] || ENV["RESEND_API_KEY"]
    end

    def build_resend_params(mail)
      params = {
        from: format_address(mail.from),
        to: format_addresses(mail.to),
        subject: mail.subject
      }

      # Add optional fields
      params[:cc] = format_addresses(mail.cc) if mail.cc.present?
      params[:bcc] = format_addresses(mail.bcc) if mail.bcc.present?
      params[:reply_to] = format_addresses(mail.reply_to) if mail.reply_to.present?

      # Handle body content
      if mail.html_part
        params[:html] = mail.html_part.body.decoded
      elsif mail.text_part
        params[:text] = mail.text_part.body.decoded
      elsif mail.content_type&.include?("text/html")
        params[:html] = mail.body.decoded
      else
        params[:text] = mail.body.decoded
      end

      # Handle attachments
      if mail.attachments.present?
        params[:attachments] = mail.attachments.map do |attachment|
          {
            filename: attachment.filename,
            content: Base64.strict_encode64(attachment.body.decoded)
          }
        end
      end

      # Add custom headers if any
      if mail.header.present?
        headers = {}
        mail.header.fields.each do |field|
          next if field.name.downcase.in?(%w[from to cc bcc subject reply-to content-type])
          headers[field.name] = field.value
        end
        params[:headers] = headers if headers.any?
      end

      params
    end

    def format_address(address)
      # Handle single address (from field)
      return address.first if address.is_a?(Array)
      address
    end

    def format_addresses(addresses)
      # Handle multiple addresses (to, cc, bcc)
      return addresses if addresses.is_a?(Array)
      [ addresses ]
    end
end
