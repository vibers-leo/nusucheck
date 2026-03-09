class AddNotificationSettingsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :email_notifications, :boolean, default: true
    add_column :users, :push_notifications, :boolean, default: true
    add_column :users, :sms_notifications, :boolean, default: false
    add_column :users, :estimate_notification, :boolean, default: true
    add_column :users, :construction_notification, :boolean, default: true
    add_column :users, :insurance_notification, :boolean, default: true
    add_column :users, :marketing_notification, :boolean, default: false
  end
end
