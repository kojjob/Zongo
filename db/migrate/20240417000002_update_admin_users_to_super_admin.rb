class UpdateAdminUsersToSuperAdmin < ActiveRecord::Migration[8.0]
  def up
    # Update existing admin users to have the super_admin role
    execute <<-SQL
      UPDATE users SET super_admin = true WHERE admin = true;
    SQL
  end

  def down
    # Revert super_admin users back to regular admin
    execute <<-SQL
      UPDATE users SET super_admin = false WHERE super_admin = true;
    SQL
  end
end
