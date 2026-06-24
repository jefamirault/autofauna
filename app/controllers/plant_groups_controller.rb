class PlantGroupsController < ApplicationController
  before_action :authenticate
  before_action :ensure_project
  before_action :set_plant_group, only: %i[ show edit update destroy water ]
  before_action :authorize_viewer, only: [:index, :show]
  before_action :authorize_editor, except: [:index, :show]

  # GET /plant_groups
  def index
    @plant_groups = current_project.plant_groups
      .left_joins(:plants)
      .where('plants.id IS NULL OR plants.archived = ?', false)
      .group('plant_groups.id')
      .order('COUNT(plants.id) DESC, LOWER(plant_groups.name) ASC')
  end

  # GET /plant_groups/1
  def show
  end

  # GET /plant_groups/new
  def new
    @plant_group = current_project.plant_groups.new
  end

  # GET /plant_groups/1/edit
  def edit
  end

  # POST /plant_groups
  def create
    @plant_group = current_project.plant_groups.new(plant_group_params)

    if @plant_group.save
      @plant_group.apply_schedule_to_members! if apply_schedule?
      redirect_to @plant_group, notice: t('plant_groups.created')
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /plant_groups/1
  def update
    if @plant_group.update(plant_group_params)
      @plant_group.apply_schedule_to_members! if apply_schedule?
      redirect_to @plant_group, notice: t('plant_groups.updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /plant_groups/1
  def destroy
    @plant_group.destroy!
    redirect_to plant_groups_path, status: :see_other, notice: t('plant_groups.destroyed')
  end

  # POST /plant_groups/1/water
  def water
    @watered = @plant_group.water_all!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to plants_path, notice: t('plant_groups.watered', count: @watered.size) }
    end
  end

  # POST /plant_groups/seed_from_location
  def seed_from_location
    location = current_project.locations.find(params[:location_id])
    @plant_group = current_project.plant_groups.create!(
      name: location.name,
      color: location.hex_color,
      plant_ids: location.plants.pluck(:id)
    )
    redirect_to edit_plant_group_path(@plant_group), notice: t('plant_groups.seeded', name: location.name)
  end

  private
    def set_plant_group
      @plant_group = current_project.plant_groups.find(params[:id])
    end

    def plant_group_params
      params.require(:plant_group).permit(:name, :color, :min_watering_freq, :max_watering_freq, plant_ids: [])
    end

    def apply_schedule?
      ActiveModel::Type::Boolean.new.cast(params[:apply_schedule])
    end
end
