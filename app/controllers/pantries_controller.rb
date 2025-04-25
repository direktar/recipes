class PantriesController < ApplicationController
  def show
    @user_ingredients = current_user.user_ingredients.includes(:ingredient)
  end

  def edit
    show
    @user_ingredient = current_user.user_ingredients.build
  end

  def update
    # не потрібен: окремі add/remove робимо через UserIngredientsController
  end
end
