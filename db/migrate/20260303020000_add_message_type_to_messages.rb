class AddMessageTypeToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :message_type, :integer, default: 0, null: false

    # sender를 nullable로 변경 (시스템 메시지는 sender 없음)
    change_column_null :messages, :sender_id, true

    add_index :messages, :message_type
  end
end
