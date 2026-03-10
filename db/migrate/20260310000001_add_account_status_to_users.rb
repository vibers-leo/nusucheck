class AddAccountStatusToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :account_status, :integer, default: 0, null: false
    add_column :users, :guest_token, :string
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_index :users, :guest_token, unique: true
    add_index :users, [:provider, :uid], unique: true

    # 기존 유저는 모두 registered로 설정
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE users SET account_status = 1 WHERE account_status = 0;
        SQL
      end
    end
  end
end
