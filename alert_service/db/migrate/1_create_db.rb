require 'active_record'
require_relative '../../model/alert'

class CreateDb < ActiveRecord::Migration
  def up
    create_table :alerts do |t|
      t.column :ticker, :string, null: false
      t.column :value, :float, null: false
      t.column :predicate, :string, null: false
      t.column :email, :string
      t.column :phone, :string
      t.column :last_notified, :timestamp
    end

    initialize_data
  end

  def down
    drop_table :alerts
  end

  def initialize_data
    Alert.create do |a|
      a.ticker = 'AAAAA'
      a.value = 50
      a.predicate = 'LT'
      a.email = 'john.doe@example.com'
      a.phone = '+15555555555'
    end
  end
end
