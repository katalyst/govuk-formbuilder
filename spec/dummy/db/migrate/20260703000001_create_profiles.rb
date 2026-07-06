# frozen_string_literal: true

class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles do |t|
      t.string :name
      t.string :email
      t.text :bio
      t.boolean :active, default: false, null: false
      t.date :born_on
      t.integer :age
      t.integer :status, default: 0, null: false
      t.string :country
      t.string :website
      t.string :phone

      t.timestamps
    end
  end
end
