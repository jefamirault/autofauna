class LocationsController < ApplicationController
  before_action :authenticate
  before_action :ensure_project
  before_action :set_location, only: %i[ show edit update destroy water_all ]
  before_action :authorize_viewer, only: [:index, :show]
  before_action :authorize_editor, except: [:index, :show]

  # POST /locations/1/water_all
  def water_all
    @watered = @location.water_all!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to plants_path, notice: t('plant_groups.watered', count: @watered.size) }
    end
  end

  # GET /locations or /locations.json
  def index
    @locations = current_project.locations
      .left_joins(:plants)
      .where('plants.id IS NULL OR plants.archived = ?', false)
      .group('locations.id')
      .order('COUNT(plants.id) DESC, LOWER(locations.name) ASC')
  end

  # GET /locations/1 or /locations/1.json
  def show
  end

  # GET /locations/new
  def new
    @location = Location.new
  end

  # GET /locations/1/edit
  def edit
  end

  # POST /locations or /locations.json
  def create
    @location = Location.new(location_params)

    respond_to do |format|
      if @location.save
        format.html { redirect_to @location, notice: "Location was successfully created." }
        format.json { render :show, status: :created, location: @location }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /locations/1 or /locations/1.json
  def update
    respond_to do |format|
      if @location.update(location_params)
        format.html { redirect_to @location, notice: "Location was successfully updated." }
        format.json { render :show, status: :ok, location: @location }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /locations/1 or /locations/1.json
  def destroy
    @location.destroy!

    respond_to do |format|
      format.html { redirect_to locations_path, status: :see_other, notice: "Location was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_location
      @location = current_project.locations.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def location_params
      params.expect(location: [ :zone_id, :name, :description, :project_id, :color])
    end
end
