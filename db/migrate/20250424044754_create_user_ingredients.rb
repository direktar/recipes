class CreateUserIngredients < ActiveRecord::Migration[8.0]
  def change
    create_table :user_ingredients do |t|
      t.references :user, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true
      t.float :quantity
      t.string :unit

      t.timestamps
    end
  end
end
