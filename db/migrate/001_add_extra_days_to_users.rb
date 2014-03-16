class AddExtraDaysToUsers < ActiveRecord::Migration
  def up
    add_column :users, :extra_days, :text, :default => nil, :null => true
    User.reset_column_information
    User.all.each do |user|
      user.update_attribute(:extra_days, {:current_year => user.extra_days.to_i, :previous_year => 0})
    end
  end

  def down
    remove_column :users, :extra_days
  end
end