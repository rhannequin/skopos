# frozen_string_literal: true

class CreateObservatories < ActiveRecord::Migration[8.1]
  def change
    create_table :observatories do |t|
      t.string :code, null: false, index: {unique: true}
      t.string :name, null: false
      t.float :longitude, null: false
      t.float :parallax_cos, null: false
      t.float :parallax_sin, null: false

      t.timestamps
    end
  end
end
