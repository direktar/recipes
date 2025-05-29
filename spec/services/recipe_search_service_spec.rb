require 'rails_helper'

RSpec.describe RecipeSearchService, type: :service do
  describe '#call' do
    let(:user) { create(:user) }

    let!(:tomato) { create(:ingredient, name: 'tomato') }
    let!(:onion) { create(:ingredient, name: 'onion') }
    let!(:pasta) { create(:ingredient, name: 'pasta') }

    let!(:tomato_soup) do
      recipe = create(:recipe, title: 'Tomato Soup')
      create(:recipe_ingredient, recipe: recipe, ingredient: tomato)
      create(:recipe_ingredient, recipe: recipe, ingredient: onion)
      recipe
    end

    let!(:pasta_dish) do
      recipe = create(:recipe, title: 'Pasta Dish')
      create(:recipe_ingredient, recipe: recipe, ingredient: pasta)
      create(:recipe_ingredient, recipe: recipe, ingredient: tomato)
      recipe
    end

    before do
      # Enable callbacks specifically for this block
      Searchkick.enable_callbacks
      Recipe.reindex
      # Refresh the index to make sure changes are available for search
      Recipe.searchkick_index.refresh
    ensure
      # Always disable callbacks after the block
      Searchkick.disable_callbacks
    end

    context 'with no parameters' do
      it 'returns all recipes' do
        service = RecipeSearchService.new
        expect(service.call).to include(tomato_soup, pasta_dish)
      end
    end

    context 'with search query parameters' do
      it 'searches recipes by ingredient query' do
        service = RecipeSearchService.new(
          recipe_search_form: { query: 'tomato' }
        )

        result = service.call
        expect(result).to include(tomato_soup, pasta_dish)
      end

      it 'searches recipes by specific ingredient' do
        service = RecipeSearchService.new(
          recipe_search_form: { query: 'pasta' }
        )

        result = service.call
        expect(result).to include(pasta_dish)
        expect(result).not_to include(tomato_soup)
      end

      it 'searches recipes by multiple ingredients' do
        service = RecipeSearchService.new(
          recipe_search_form: { query: 'tomato, onion' }
        )

        result = service.call
        expect(result).to include(tomato_soup)
      end

      it 'returns all recipes when query is blank' do
        service = RecipeSearchService.new(
          recipe_search_form: { query: '' }
        )

        expect(service.call).to include(tomato_soup, pasta_dish)
      end

      it 'handles whitespace in the query' do
        service = RecipeSearchService.new(
          recipe_search_form: { query: '  tomato  ,  onion  ' }
        )

        result = service.call
        expect(result).to include(tomato_soup)
      end
    end

    context 'when using user ingredients' do
      before do
        create(:user_ingredient, user: user, ingredient: tomato)
        create(:user_ingredient, user: user, ingredient: onion)
      end

      it 'searches based on user ingredients' do
        service = RecipeSearchService.new({ use_my_ingredients: true }, user)

        result = service.call
        expect(result).to include(tomato_soup, pasta_dish)
      end

      it 'returns no recipes when user has no ingredients' do
        # Remove all user ingredients
        user.user_ingredients.destroy_all

        service = RecipeSearchService.new({ use_my_ingredients: true }, user)

        expect(service.call).to be_empty
      end
    end

    context 'with multiple conditions' do
      before do
        create(:user_ingredient, user: user, ingredient: tomato)
        create(:user_ingredient, user: user, ingredient: onion)
      end

      it 'prioritizes user ingredients over query when both are provided' do
        service = RecipeSearchService.new(
          {
            use_my_ingredients: true,
            recipe_search_form: { query: 'pasta' }
          },
          user
        )

        # It should use user ingredients search since use_my_ingredients is true
        result = service.call
        expect(result).to include(tomato_soup, pasta_dish)
      end
    end
  end

  # describe '#search_by_ingredient_query' do
  #   let!(:tomato) { create(:ingredient, name: 'tomato') }
  #   let!(:pasta) { create(:ingredient, name: 'pasta') }
  #   let!(:cheese) { create(:ingredient, name: 'cheese') }
  #
  #   let!(:tomato_pasta) do
  #     recipe = create(:recipe, title: 'Tomato Pasta')
  #     create(:recipe_ingredient, recipe: recipe, ingredient: tomato)
  #     create(:recipe_ingredient, recipe: recipe, ingredient: pasta)
  #     recipe
  #   end
  #
  #   let!(:cheese_pasta) do
  #     recipe = create(:recipe, title: 'Cheese Pasta')
  #     create(:recipe_ingredient, recipe: recipe, ingredient: cheese)
  #     create(:recipe_ingredient, recipe: recipe, ingredient: pasta)
  #     recipe
  #   end
  #
  #   before do
  #     Searchkick.enable_callbacks
  #     Recipe.reindex
  #     Recipe.searchkick_index.refresh
  #   ensure
  #     Searchkick.disable_callbacks
  #   end
  #
  #   it 'returns recipes matching the ingredient query' do
  #     service = RecipeSearchService.new
  #
  #     result = service.send(:search_by_ingredient_query, 'tomato')
  #     expect(result).to include(tomato_pasta)
  #     expect(result).not_to include(cheese_pasta)
  #   end
  #
  #   it 'returns recipes matching multiple ingredients with AND operator' do
  #     service = RecipeSearchService.new
  #
  #     result = service.send(:search_by_ingredient_query, 'tomato, pasta')
  #     expect(result).to include(tomato_pasta)
  #     expect(result).not_to include(cheese_pasta)
  #   end
  #
  #   it 'returns all recipes when no ingredients are specified' do
  #     service = RecipeSearchService.new
  #
  #     result = service.send(:search_by_ingredient_query, '')
  #     expect(result).to include(tomato_pasta, cheese_pasta)
  #   end
  # end
  #
  # describe '#search_by_user_ingredients' do
  #   let(:user) { create(:user) }
  #   let!(:tomato) { create(:ingredient, name: 'tomato') }
  #   let!(:onion) { create(:ingredient, name: 'onion') }
  #   let!(:pasta) { create(:ingredient, name: 'pasta') }
  #
  #   let!(:tomato_onion_recipe) do
  #     recipe = create(:recipe, title: 'Tomato and Onion Recipe')
  #     create(:recipe_ingredient, recipe: recipe, ingredient: tomato)
  #     create(:recipe_ingredient, recipe: recipe, ingredient: onion)
  #     recipe
  #   end
  #
  #   let!(:pasta_recipe) do
  #     recipe = create(:recipe, title: 'Pasta Recipe')
  #     create(:recipe_ingredient, recipe: recipe, ingredient: pasta)
  #     recipe
  #   end
  #
  #   before do
  #     # Add tomato and onion to user's ingredients
  #     create(:user_ingredient, user: user, ingredient: tomato)
  #     create(:user_ingredient, user: user, ingredient: onion)
  #
  #     Searchkick.enable_callbacks
  #     Recipe.reindex
  #     Recipe.searchkick_index.refresh
  #   ensure
  #     Searchkick.disable_callbacks
  #   end
  #
  #   it 'searches recipes based on user ingredients' do
  #     service = RecipeSearchService.new({}, user)
  #
  #     result = service.send(:search_by_user_ingredients)
  #     expect(result).to include(tomato_onion_recipe)
  #     expect(result).not_to include(pasta_recipe)
  #   end
  #
  #   it 'returns no recipes when user has no ingredients' do
  #     user.user_ingredients.destroy_all
  #     service = RecipeSearchService.new({}, user)
  #
  #     expect(service.send(:search_by_user_ingredients)).to be_empty
  #   end
  # end
end
