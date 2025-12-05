# Single Tenancy Configuration for Development
# This file configures Fizzy to work in single-tenant mode for local development

if Rails.env.development? && ENV['SINGLE_TENANT'].present?
  Rails.application.config.after_initialize do
    # Create or find the default account for single-tenant mode
    default_account = Account.find_or_create_by!(external_account_id: 1) do |account|
      account.name = "Default Account"
    end

    # Set the default account globally
    Rails.application.config.x.default_account = default_account
    
    puts "✓ Single-tenant mode enabled with Account ID: #{default_account.id}"
  end
end
