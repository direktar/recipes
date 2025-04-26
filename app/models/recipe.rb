# == Schema Information
#
# Table name: recipes
#
#  id               :bigint           not null, primary key
#  description      :text
#  difficulty       :string
#  instructions     :text
#  preparation_time :integer
#  title            :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class Recipe < ApplicationRecord
  has_many :recipe_ingredients, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients

  validates :title, presence: true

  def preparation_time_text
    return "Unknown" if preparation_time.blank?

    hours = preparation_time / 60
    minutes = preparation_time % 60

    if hours > 0
      minutes > 0 ? "#{hours} hour #{minutes} minutes" : "#{hours} hours"
    else
      "#{minutes} minutes"
    end
  end

  def self.find_by_user_ingredients(user)
    return none if user.user_ingredients.empty?

    recipes_with_ingredient_stats = find_by_sql([<<-SQL, user.id, user.id])
    WITH user_ingredients_with_details AS (
      SELECT ui.ingredient_id, ui.quantity, ui.unit
      FROM user_ingredients ui
      WHERE ui.user_id = ?
    ),
    recipe_counts AS (
      SELECT 
        ri.recipe_id,
        COUNT(ri.ingredient_id) AS total_ingredients_count
      FROM recipe_ingredients ri
      GROUP BY ri.recipe_id
    ),
    matching_ingredients AS (
      SELECT 
        ri.recipe_id,
        ri.ingredient_id,
        CASE 
          WHEN ui.unit = ri.unit AND ui.quantity >= ri.quantity THEN 1
          WHEN ui.unit IS NULL OR ri.unit IS NULL THEN 1
          WHEN ui.quantity IS NULL THEN 1
          ELSE 0
        END AS has_sufficient_quantity
      FROM recipe_ingredients ri
      JOIN user_ingredients_with_details ui ON ri.ingredient_id = ui.ingredient_id
    ),
    recipe_matches AS (
      SELECT 
        mi.recipe_id,
        COUNT(mi.ingredient_id) AS matching_ingredients_count,
        SUM(mi.has_sufficient_quantity) AS sufficient_quantity_count
      FROM matching_ingredients mi
      GROUP BY mi.recipe_id
    )
    SELECT 
      r.id,
      r.title,
      r.description,
      r.instructions,
      r.preparation_time,
      r.difficulty,
      rc.total_ingredients_count,
      rm.matching_ingredients_count,
      rm.sufficient_quantity_count,
      CASE 
        WHEN rm.matching_ingredients_count = rc.total_ingredients_count 
          AND rm.sufficient_quantity_count = rc.total_ingredients_count 
        THEN 1 
        ELSE 0 
      END AS can_make_recipe
    FROM recipes r
    JOIN recipe_counts rc ON r.id = rc.recipe_id
    JOIN recipe_matches rm ON r.id = rm.recipe_id
    WHERE EXISTS (
      SELECT 1 FROM user_ingredients ui WHERE ui.user_id = ?
    )
    ORDER BY 
      can_make_recipe DESC,
      sufficient_quantity_count DESC, 
      matching_ingredients_count DESC, 
      total_ingredients_count ASC,
      r.title ASC
  SQL

    recipe_ids = recipes_with_ingredient_stats.select { |r| r.can_make_recipe == 1 }.map(&:id)
    where(id: recipe_ids).includes(:recipe_ingredients, :ingredients).order(:title)
  end


end
