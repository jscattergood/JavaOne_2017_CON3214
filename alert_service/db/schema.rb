require 'active_record'

ActiveRecord::Schema.define do
  create_table :alerts do |t|
    t.column :ticker, :string, null: false
    t.column :value, :float, null: false
    t.column :predicate, :string, null: false
    t.column :phone, :string
    t.column :last_triggered, :timestamp
    t.column :last_notified, :timestamp
  end
end
