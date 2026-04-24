class RecipesController < ApplicationController
  before_action :authenticate
  before_action :ensure_project
  before_action :set_recipe, only: %i[show edit update destroy]
  before_action :authorize_viewer, only: [:index, :show]
  before_action :authorize_editor, except: [:index, :show]

  def index
    @recipes = current_project.recipes.includes(:recipe_sources, :recipe_batches)
  end

  def show
    @recipe_ingredients = @recipe.recipe_ingredients.includes(:recipe_source)
    @active_batches = @recipe.recipe_batches.active
  end

  def new
    @recipe = Recipe.new
    @recipe.recipe_ingredients.build
  end

  def edit
    @recipe.recipe_ingredients.build if @recipe.recipe_ingredients.empty?
  end

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

  def destroy
    @recipe.destroy!

    respond_to do |format|
      format.html { redirect_to recipes_path, status: :see_other, notice: "Recipe was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_recipe
    @recipe = current_project.recipes.find(params.expect(:id))
  end

  def recipe_params
    params.require(:recipe).permit(:name, :description, :project_id, :color, :default_tds,
      recipe_ingredients_attributes: [:id, :recipe_source_id, :amount, :units, :position, :_destroy])
  end
end
