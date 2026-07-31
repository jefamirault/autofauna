class LocationsController < ApplicationController
  before_action :authenticate
  before_action :ensure_project
  before_action :set_location, only: %i[ show edit update destroy water_all update_layout ]
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

  # PATCH /locations/1/layout
  # Saves the diagram positions for a batch of chips. Coordinates are normalized 0.0–1.0;
  # a null pair sends the plant back to the tray.
  def update_layout
    positions = layout_positions
    plants = @location.plants.where(id: positions.keys).index_by(&:id)

    plants.each do |id, plant|
      x, y = positions[id]
      # `update_columns`, not `update!`: coordinates are already clamped, and a chip move
      # must not fail because the plant carries an unrelated validation error (a duplicate
      # uid from an import, say). The model validation still guards every other path.
      plant.update_columns(layout_x: x, layout_y: y)
    end

    respond_to do |format|
      format.json { render json: { saved: plants.keys } }
      format.html { redirect_to @location }
    end
  end

  # GET /locations or /locations.json
  def index
    @locations = current_project.locations
      .with_attached_picture
      .left_joins(:plants)
      .where('plants.id IS NULL OR plants.archived = ?', false)
      .group('locations.id')
      .order('COUNT(plants.id) DESC, LOWER(locations.name) ASC')

    # Deliberately a second query: the relation above is grouped for the plant-count
    # ordering, so plant rows can't be preloaded onto it.
    @layout_points = current_project.plants
      .where(archived: false)
      .where.not(layout_x: nil).where.not(layout_y: nil)
      .pluck(:location_id, :layout_x, :layout_y)
      .group_by(&:first)
      .transform_values { |rows| rows.map { |(_, x, y)| [x, y] } }
  end

  # GET /locations/1 or /locations/1.json
  def show
    @diagram_plants = @location.diagram_plants
      .includes(:plant_groups, :recipes, :recipe, custom_image_attachment: :blob)
      .order(:uid)
      .to_a
    # Legends are derived from the plants standing here, not the project-wide lists.
    @diagram_groups = tally_by_name(@diagram_plants.flat_map(&:plant_groups))
    @diagram_recipes = feature_enabled?(:use_fertilizers) ? tally_by_name(@diagram_plants.flat_map(&:recipes)) : []

    if feature_enabled?(:use_fertilizers)
      @location_supplies = @location.location_supplies.includes(:supplyable).to_a
      @available_sources = current_project.recipe_sources.order(:name)
      @available_batches = current_project.recipe_batches.active.includes(:recipe).order(mixed_on: :desc)
    end
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
        purge_picture_if_requested
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
      params.expect(location: [ :zone_id, :name, :description, :project_id, :color, :picture])
    end

    # [[record, count], …] sorted by name — AR objects hash by id, so `tally` de-dupes them.
    def tally_by_name(records)
      records.tally.sort_by { |record, _count| record.name.to_s.downcase }
    end

    # { plant_id => [x, y] }, coordinates clamped into the canvas or nilled to unplace.
    # Ids are *not* trusted here — the caller filters them through `@location.plants`.
    def layout_positions
      raw = params[:positions]
      entries = raw.respond_to?(:values) ? raw.values : Array(raw)

      entries.each_with_object({}) do |entry, acc|
        next unless entry.respond_to?(:[])

        id = entry[:id].to_i
        next if id.zero?

        x, y = entry[:x], entry[:y]
        acc[id] = if x.nil? || y.nil? || x == "" || y == ""
          [nil, nil]
        else
          [clamp_unit(x), clamp_unit(y)]
        end
      end
    end

    def clamp_unit(value)
      value.to_f.clamp(0.0, 1.0).round(4)
    end

    def purge_picture_if_requested
      return unless params.dig(:location, :remove_picture) == "1"
      return if location_params[:picture].present?

      @location.picture.purge
    end
end
