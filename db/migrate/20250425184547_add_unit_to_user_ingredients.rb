class AddUnitToUserIngredients < ActiveRecord::Migration[8.0]
  def change
    add_column :user_ingredients, :unit, :string
  end
end
