require 'active_record'
require_relative '../../model/rule'

class CreateDb < ActiveRecord::Migration
  def up
    create_table :rules do |t|
      t.column :ticker, :string, null: false
      t.column :value, :float, null: false
      t.column :predicate, :string, null: false
      t.column :phone, :string
      t.column :last_triggered, :timestamp
      t.column :last_notified, :timestamp
    end

    initialize_data
  end

  def down
    drop_table :rule
  end

  def initialize_data
    Rule.create do |r|
      r.ticker = 'AAAAA'
      r.value = 50
      r.predicate = 'LT'
      r.phone = '+15555555555'
    end
  end
end
