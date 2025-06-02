class RecipesController < ApplicationController
  include Pagy::Backend

  before_action :set_recipe, only: %i[ show edit update destroy ]

  # GET /recipes or /recipes.json
  def index
    @search_form = RecipeSearchForm.new(query: params[:query])

    if request.get? && params[:query].present? && !@search_form.valid?
      @recipes = Recipe.all.includes(:ingredients)
      flash.now[:alert] = @search_form.errors.full_messages.join(", ")
    else
      recipes = RecipeSearchService.call(params, current_user)
      @pagy, @recipes = pagy_searchkick(recipes, items: Pagy::DEFAULT[:items])
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
