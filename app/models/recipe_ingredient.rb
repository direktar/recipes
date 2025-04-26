# == Schema Information
#
# Table name: recipe_ingredients
#
#  id            :bigint           not null, primary key
#  notes         :string
#  quantity      :float
#  unit          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  ingredient_id :bigint           not null
#  recipe_id     :bigint           not null
#
# Indexes
#
#  index_recipe_ingredients_on_ingredient_id  (ingredient_id)
#  index_recipe_ingredients_on_recipe_id      (recipe_id)
#
# Foreign Keys
#
#  fk_rails_...  (ingredient_id => ingredients.id)
#  fk_rails_...  (recipe_id => recipes.id)
#
class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :ingredient

  validates :recipe_id, uniqueness: { scope: :ingredient_id }

  def display_amount
    return "" if quantity.blank? && unit.blank?

    quantity_text = quantity.present? ? format_quantity(quantity) : ""
    unit_text = unit.present? ? unit : ""

    [quantity_text, unit_text].reject(&:blank?).join(" ")
  end

  private

  def format_quantity(qty)
    return qty.to_i.to_s if qty == qty.to_i

    case qty
    when 0.25 then "1/4"
    when 0.5 then "1/2"
    when 0.75 then "3/4"
    when 0.33, 0.34 then "1/3"
    when 0.66, 0.67 then "2/3"
    else qty.to_s
    end
  end
end
