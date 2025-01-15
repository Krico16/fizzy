class AddStatusToBubbles < ActiveRecord::Migration[8.1]
  def change
    add_column :bubbles, :status, :text, default: :drafted, null: false
  end
end
