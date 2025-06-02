class RecipeSearchService
  include ApplicationService

  attr_reader :params, :user

  def initialize(params = {}, user = nil)
    @params = params
    @user = user
  end

  def call
    if params[:use_my_ingredients] && user.present?
      search_by_user_ingredients
    elsif params[:recipe_search_form].present?
      search_by_query(params.dig(:recipe_search_form, :query))
    else
      default_recipes
    end
  end

  private

  def search_by_query(query)
    return default_recipes if query.nil?

    ingredients = query.split(",").map(&:strip).reject(&:blank?)
    if ingredients.any?
      lowercase_ingredients = ingredients.map(&:downcase)
      pagy_recipes = Recipe.pagy_search(
        "*",
        where: {
          ingredients_lowercase: { all: lowercase_ingredients }
        },
        load: true
      )
      pagy_recipes.includes(:ingredients)
    else
      default_recipes
    end
  end

  def search_by_user_ingredients
    user_ingredient_names = user.ingredients.pluck(:name)

    if user_ingredient_names.any?
      all_recipes = Recipe.search("*", load: false, select: [:ingredients_lowercase])
      filtered_recipe_ids = all_recipes.select do |recipe|
        (recipe.ingredients_lowercase - user_ingredient_names.map(&:downcase)).empty?
      end.map(&:id)

      Recipe.pagy_search(
        where: { id: filtered_recipe_ids },
        includes: [:ingredients]
      )
    else
      Recipe.pagy_search("*", where: { id: [] })
    end
  end



  def default_recipes
    Recipe.pagy_search("*", load: true).includes(:ingredients)
  end
end
