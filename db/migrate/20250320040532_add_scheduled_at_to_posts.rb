class AddScheduledAtToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :scheduled_at, :datetime
  end
end
