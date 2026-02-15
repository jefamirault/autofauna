class RecipeSourcesController < ApplicationController
  before_action :set_recipe_source, only: %i[show edit update destroy]
  before_action :authorize_viewer, only: [:index, :show]
  before_action :authorize_editor, except: [:index, :show]

  def index
    @recipe_sources = current_project.recipe_sources
  end

  def show
  end

  def new
    @recipe_source = RecipeSource.new
  end

  def edit
  end

  def create
    @recipe_source = RecipeSource.new(recipe_source_params)

    respond_to do |format|
      if @recipe_source.save
        format.html { redirect_to @recipe_source, notice: "Source was successfully created." }
        format.json { render :show, status: :created, location: @recipe_source }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @recipe_source.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @recipe_source.update(recipe_source_params)
        format.html { redirect_to @recipe_source, notice: "Source was successfully updated." }
        format.json { render :show, status: :ok, location: @recipe_source }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @recipe_source.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @recipe_source.destroy!

    respond_to do |format|
      format.html { redirect_to recipe_sources_path, status: :see_other, notice: "Source was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_recipe_source
    @recipe_source = RecipeSource.find(params.expect(:id))
  end

  def recipe_source_params
    params.require(:recipe_source).permit(:name, :tank_id, :description, :project_id)
  end
end
