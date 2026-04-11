class AddRotationFieldsToZoneClaims < ActiveRecord::Migration[7.1]
  def change
    add_column :zone_claims, :last_assigned_at, :datetime
    add_column :zone_claims, :total_assignments, :integer, default: 0
    add_column :zone_claims, :active_assignments, :integer, default: 0

    # 모든 구역 3슬롯으로 통일
    ServiceZone.update_all(max_slots: 3)
  end
end
