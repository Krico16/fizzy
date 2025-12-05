# Single Tenant Seeds
# Run with: SINGLE_TENANT=true rails db:seed:single_tenant

return unless ENV['SINGLE_TENANT'].present?

puts "Setting up single-tenant development environment..."

# Create default account
account = Account.find_or_create_by!(external_account_id: 1) do |a|
  a.name = "Default Account"
end

puts "✓ Account created: #{account.name} (ID: #{account.external_account_id})"

# Create default identity and user
identity = Identity.find_or_create_by!(email_address: "dev@localhost")

user = User.find_or_create_by!(account: account, identity: identity) do |u|
  u.name = "Dev User"
  u.role = :owner
end

puts "✓ User created: #{user.name} (#{identity.email_address})"

# Set current user for board creation
Current.user = user

# Create a sample board
board = Board.find_or_create_by!(account: account, name: "Tasks") do |b|
  b.creator = user
  b.all_access = true
end

puts "✓ Board created: #{board.name}"

# Create default columns
columns = [
  { name: "Triage", position: 0 },
  { name: "In Progress", position: 1 },
  { name: "Done", position: 2 }
]

columns.each do |col_attrs|
  column = Column.find_or_create_by!(
    board: board,
    name: col_attrs[:name]
  ) do |c|
    c.position = col_attrs[:position]
  end
  puts "  ✓ Column: #{column.name}"
end

puts "\n✅ Single-tenant environment ready!"
puts "   Login email: #{identity.email_address}"
puts "   Access the app at: http://localhost:3006"
