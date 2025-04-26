class RecipesController < ApplicationController
  include Pagy::Backend

  before_action :set_recipe, only: %i[ show edit update destroy ]

  # GET /recipes or /recipes.json
  def index
    @recipes = Recipe.all.includes(:ingredients)

    if params[:query].present?
      ingredients = params[:query].split(',').map(&:strip).reject(&:blank?)

      if ingredients.any?
        @recipes = ingredients.inject(@recipes) do |scope, ingredient|
          scope.joins(:ingredients)
               .where("
               ingredients.name ILIKE ? OR
               ingredients.name ILIKE ? OR
               ingredients.name ILIKE ? OR
               ingredients.name ILIKE ?
             ",
               ingredient,
               "#{ingredient} %",
               "% #{ingredient}",
               "% #{ingredient} %"
          )
        end.distinct
      end
    end

    @pagy, @recipes = pagy(@recipes)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # GET /recipes/my_ingredients
  def my_ingredients
    @recipes = Recipe.find_by_user_ingredients(current_user)

    if @recipes.empty?
      flash.now[:notice] = "You don't have enough ingredients to make any recipes. Add more ingredients to your pantry!"
    end

    @pagy, @recipes = pagy(@recipes)
    respond_to do |format|
      format.html { render :index }
      format.turbo_stream { render :index }
    end
  end


  # GET /recipes/1 or /recipes/1.json
  def show
    respond_to do |format|
      format.html
      format.json { render :show }
    end
  end


  # GET /recipes/new
  def new
    @recipe = Recipe.new
  end

  # GET /recipes/1/edit
  def edit
  end

  # POST /recipes or /recipes.json
  def create
    @recipe = Recipe.new(recipe_params)

    respond_to do |format|
      if @recipe.save
        format.html { redirect_to @recipe, notice: "Recipe was successfully created." }
        format.json { render :show, status: :created, location: @recipe }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @recipe.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /recipes/1 or /recipes/1.json
  def update
    respond_to do |format|
      if @recipe.update(recipe_params)
        format.html { redirect_to @recipe, notice: "Recipe was successfully updated." }
        format.json { render :show, status: :ok, location: @recipe }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @recipe.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /recipes/1 or /recipes/1.json
  def destroy
    @recipe.destroy!

    respond_to do |format|
      format.html { redirect_to recipes_path, status: :see_other, notice: "Recipe was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_recipe
    @recipe = Recipe.find(params.require(:id))
  end

  # Only allow a list of trusted parameters through.
  def recipe_params
    params.require(:recipe).permit(:title, :description, :instructions, :preparation_time, :difficulty)
  end
end
