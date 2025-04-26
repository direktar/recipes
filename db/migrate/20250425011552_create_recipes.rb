class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.string :title
      t.text :description
      t.text :instructions
      t.integer :preparation_time
      t.string :difficulty

      t.timestamps
    end
  end
end
