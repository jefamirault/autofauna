class RecipeBatchesController < ApplicationController
  before_action :authenticate
  before_action :ensure_project
  before_action :require_use_fertilizers
  before_action :set_recipe_batch, only: %i[show edit update destroy adjust_remaining]
  before_action :authorize_viewer, only: [:index, :show, :for_recipe, :for_project]
  before_action :authorize_editor, except: [:index, :show, :for_recipe, :for_project]

  def index
    urgency_order = { critical: 0, soon: 1, no_usage: 2, ok: 3 }
    @active_batches = current_project.recipe_batches.includes(:recipe, :waterings).active
                                     .order(mixed_on: :desc)
                                     .sort_by { |b| urgency_order[b.replenishment_urgency] }
    @inactive_batches = current_project.recipe_batches.includes(:recipe).where(active: false).order(mixed_on: :desc)
  end

  def show
  end

  def new
    @recipe_batch = RecipeBatch.new(mixed_on: Date.current)
    @recipe_batch.recipe_id = params[:recipe_id] if params[:recipe_id]
  end

  def edit
  end

  def create
    @recipe_batch = RecipeBatch.new(recipe_batch_params)

    respond_to do |format|
      if @recipe_batch.save
        format.html { redirect_to @recipe_batch, notice: "Batch was successfully created." }
        format.json { render :show, status: :created, location: @recipe_batch }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @recipe_batch.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @recipe_batch.update(recipe_batch_params)
        format.html { redirect_to @recipe_batch, notice: "Batch was successfully updated." }
        format.json { render :show, status: :ok, location: @recipe_batch }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @recipe_batch.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @recipe_batch.destroy!

    respond_to do |format|
      format.html { redirect_to recipe_batches_path, status: :see_other, notice: "Batch was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def adjust_remaining
    volume = params[:volume].to_f
    units = params[:units].presence || @recipe_batch.volume_units
    action = params[:adjust_action]

    if action == "add"
      @recipe_batch.increment_remaining!(volume, units)
    elsif action == "subtract"
      @recipe_batch.decrement_remaining!(volume, units)
    elsif action == "set"
      @recipe_batch.update!(remaining_volume: volume, last_adjusted_at: Time.current)
    end

    respond_to do |format|
      format.html { redirect_to @recipe_batch, notice: "Remaining volume updated." }
      format.json { render json: { remaining_volume: @recipe_batch.remaining_volume } }
    end
  end

  def for_recipe
    batches = current_project.recipe_batches.active.where(recipe_id: params[:recipe_id])
    render json: batches.map { |b| { id: b.id, label: b.label, tds: b.tds } }
  end

  def for_project
    batches = current_project.recipe_batches.includes(:recipe).active.order(mixed_on: :desc)
    render json: batches.map { |b|
      { id: b.id, label: b.label, tds: b.tds,
        recipe_id: b.recipe_id, recipe_name: b.recipe.name,
        recipe_default_tds: b.recipe.default_tds }
    }
  end

  private

  def set_recipe_batch
    @recipe_batch = current_project.recipe_batches.find(params.expect(:id))
  end

  def recipe_batch_params
    params.require(:recipe_batch).permit(:recipe_id, :tds, :volume, :volume_units, :mixed_on, :notes, :active, :project_id, :remaining_volume)
  end
end
