class UserIngredientsController < ApplicationController
  before_action :set_user_ingredient, only: %i[edit update destroy]

  def create
    @user_ingredient = current_user.user_ingredients.new(ui_params)
    if @user_ingredient.save
      redirect_to pantry_path, notice: "Ingredient added!"
    else
      render "pantries/edit", status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @user_ingredient.update(ui_params)
      redirect_to pantry_path, notice: "Updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user_ingredient.destroy
    redirect_to pantry_path, notice: "Removed!"
  end

  private

  def set_user_ingredient
    @user_ingredient = current_user.user_ingredients.find(params[:id])
  end

  def ui_params
    params.require(:user_ingredient).permit(:ingredient_id, :quantity, :unit)
  end
end
