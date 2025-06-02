class UserIngredientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_ingredient, only: [:destroy, :update]

  def index
    @user_ingredients = current_user.user_ingredients.includes(:ingredient).order("ingredients.name")
    @ingredients = Ingredient.order(:name)
    @user_ingredient = UserIngredient.new
  end

  def create
    @user_ingredient = current_user.user_ingredients.new(user_ingredient_params)

    respond_to do |format|
      if @user_ingredient.save
        format.html { redirect_to user_ingredients_path, notice: "Ingredient was successfully added to your pantry." }
        format.turbo_stream { flash.now[:notice] = "Ingredient was successfully added to your pantry." }
      else
        format.html {
          @user_ingredients = current_user.user_ingredients.includes(:ingredient)
          @ingredients = Ingredient.order(:name)
          render :index, status: :unprocessable_entity
        }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@user_ingredient, partial: "user_ingredients/form", locals: { user_ingredient: @user_ingredient }) }
      end
    end
  end

  def update
    respond_to do |format|
      if @user_ingredient.update(user_ingredient_params)
        format.html { redirect_to user_ingredients_path, notice: "Ingredient quantity was successfully updated." }
        format.turbo_stream { flash.now[:notice] = "Ingredient quantity was successfully updated." }
      else
        format.html {
          @user_ingredients = current_user.user_ingredients.includes(:ingredient)
          @ingredients = Ingredient.order(:name)
          render :index, status: :unprocessable_entity
        }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@user_ingredient, partial: "user_ingredients/user_ingredient", locals: { user_ingredient: @user_ingredient }) }
      end
    end
  end

  def destroy
    @user_ingredient = current_user.user_ingredients.find(params[:id])
    @user_ingredient.destroy!

    respond_to do |format|
      format.html { redirect_to user_ingredients_path, notice: "Ingredient was successfully removed from your pantry." }
      format.turbo_stream { flash.now[:notice] = "Ingredient was successfully removed from your pantry." }
    end
  end

  def destroy_all
    current_user.ingredients.destroy_all

    redirect_to user_ingredients_path, notice: "All ingredients were successfully removed from your pantry."
  end


  private

  def set_user_ingredient
    @user_ingredient = current_user.user_ingredients.find(params[:id])
  end

  def user_ingredient_params
    params.require(:user_ingredient).permit(:ingredient_id, :quantity, :unit)
  end
end
