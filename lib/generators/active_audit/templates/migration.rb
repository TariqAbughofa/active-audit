class <%= migration_class_name %> < ActiveRecord::Migration
  def self.up
    create_table :audits, :force => true do |t|
      t.column :item_id, :integer
      t.column :type, :string
      t.column :event, :string
      t.column :changes, :json
      t.column :user_id, :integer
      t.column :attributed_to, :json
      t.column :comment, :string
      t.column :recorded_at, :datetime
    end

    add_index :audits, [:type, :item_id], :name => 'item_index'
    add_index :audits, :user_id, :name => 'user_index'
    add_index :audits, :recorded_at
  end

  def self.down
    drop_table :audits
  end
end
