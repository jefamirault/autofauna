class PlantsController < ApplicationController
  before_action :authenticate
  before_action :set_project
  before_action :set_plant, only: %i[ show edit update destroy create_share revoke_share regenerate_share create_view_share revoke_view_share regenerate_view_share ]
  before_action :authorize_viewer, only: [:index, :show]
  before_action :authorize_editor, except: [:index, :show]

  def water
    @plant = current_project.plants.find(params[:plant_id])
    redirect_to new_watering_path(plant_id: @plant.id, volume: params[:volume], units: params[:units], notes: params[:notes],
      recipe_batch_id: params[:recipe_batch_id], recipe_id: params[:recipe_id], tds: params[:tds])
  end

  def quick_water
    @plant = current_project.plants.find(params[:plant_id])
    watering_attrs = { watered_at: Time.current }

    if (last = @plant.last_watering)
      watering_attrs.merge!(
        volume: last.volume,
        units: last.units,
        notes: last.notes,
        recipe_id: last.recipe_id,
        recipe_batch_id: last.recipe_batch_id,
        tds: last.tds
      )
    end

    @watering = @plant.waterings.create!(watering_attrs)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to plants_path }
    end
  end

  # GET /plants or /plants.json
  def index
    default_search_params = {
      archived_eq: false,
      project_id_eq: current_project.id
    }
    if params['q'].nil?
      params['q'] = default_search_params
    else
      params['q'].merge! project_id_eq: current_project.id
      params['q'].merge! archived_eq: false
    end
    @q = current_project.plants.ransack(params['q'])

    @q.sorts = ['date_max_watering asc', 'date_min_watering asc'] if @q.sorts.empty?
    @plants = @q.result(distinct: true).includes(:location, :recipe, last_watering: [:recipe_batch])

    # Build location filter buttons with colors, sorted by count (descending)
    location_counts = @plants.where.not(location_id: nil).reorder(nil).group(:location_id).count
    no_location_count = @plants.where(location_id: nil).count
    locations_with_plants = Location.where(id: location_counts.keys).order(Arel.sql("LOWER(name)"))

    @location_filters = locations_with_plants.map { |loc|
      {
        name: "#{loc.name} (#{location_counts[loc.id]})",
        id: loc.id,
        count: location_counts[loc.id],
        color: loc.hex_color
      }
    }.sort_by { |f| -f[:count] }

    @location_filters << {
      name: "#{I18n.t('plants.index.no_location')} (#{no_location_count})",
      id: nil,
      count: no_location_count,
      color: '#999999'
    } if no_location_count > 0

    # Build recipe filter buttons with colors, sorted by count (descending)
    recipe_counts = @plants.where.not(recipe_id: nil).reorder(nil).group(:recipe_id).count
    no_recipe_count = @plants.where(recipe_id: nil).count
    recipes_with_plants = Recipe.where(id: recipe_counts.keys).order(:name)

    @recipe_filters = recipes_with_plants.map { |recipe|
      {
        name: "#{recipe.name} (#{recipe_counts[recipe.id]})",
        id: recipe.id,
        count: recipe_counts[recipe.id],
        color: recipe.hex_color
      }
    }.sort_by { |f| -f[:count] }

    @recipe_filters << {
      name: "#{I18n.t('plants.index.no_recipe')} (#{no_recipe_count})",
      id: nil,
      count: no_recipe_count,
      color: '#999999'
    } if no_recipe_count > 0

    # Build watering status groups for filtering (single pass)
    urgency_counts = { urgent: 0, today: 0, normal: 0, none: 0 }
    @plants.each { |p| urgency_counts[p.watering_urgency] += 1 }

    @watering_status_groups = [
      { status: 'urgent', name: I18n.t('plants.index.overdue'), count: urgency_counts[:urgent] },
      { status: 'today', name: I18n.t('plants.index.needs_water_today'), count: urgency_counts[:today] },
      { status: 'scheduled', name: I18n.t('plants.index.scheduled'), count: urgency_counts[:normal] + urgency_counts[:none] }
    ]

    @needs_watering_count = urgency_counts[:urgent] + urgency_counts[:today]

    @saved_searches = current_project.saved_searches.where(user_id: current_user.id).order(:name)

    @display_mode = params[:display] || "watering"

    # Always build location groups (needed for client-side display mode switching)
    grouped = @plants.group_by { |p| [p.location&.name, p.location&.hex_color || '#999999'] }
    no_location = grouped.delete([nil, '#999999']) || []
    @plants_by_location = grouped.sort_by { |(name, _color), _plants| (name || '').downcase }.to_h
    @plants_by_location[[I18n.t('plants.index.no_location'), '#999999']] = no_location if no_location.any?

    # Always build recipe groups (needed for client-side display mode switching)
    grouped = @plants.group_by { |p| [p.recipe&.name, p.recipe&.hex_color || '#999999'] }
    no_recipe = grouped.delete([nil, '#999999']) || []
    @plants_by_recipe = grouped.sort_by { |(name, _color), _plants| (name || '').downcase }.to_h
    @plants_by_recipe[[I18n.t('plants.index.no_recipe'), '#999999']] = no_recipe if no_recipe.any?

    respond_to do |format|
      format.json { @plants = current_project.plants }
      format.html
    end
  end

  def archive
    default_search_params = {
      archived_eq: true,
      project_id_eq: current_project.id
    }
    force_search_params = {

    }
    if params['q'].nil?
      params['q'] = default_search_params
    else
      params['q'].merge! project_id_eq: current_project.id
      params['q'].merge! archived_eq: true
    end
    @q = current_project.plants.ransack(params['q'])

    @q.sorts = ['date_max_watering asc', 'date_min_watering asc'] if @q.sorts.empty?
    @plants = @q.result(distinct: true)

    respond_to do |format|
      format.json { @plants = current_project.plants }
      format.html
    end
  end

  # GET /plants/1 or /plants/1.json
  def show
    @log_entries = @plant.log_entries.reverse

    # Combine log entries, waterings, and standalone moisture readings into a single timeline
    log_items = @log_entries.map { |entry| { type: :log_entry, date: entry.timestamp, object: entry } }
    watering_items = @plant.waterings.map { |watering| { type: :watering, date: watering.watered_at, object: watering } }
    moisture_items = @plant.soil_moisture_readings.where(timing: :standalone).map { |reading| { type: :moisture_reading, date: reading.measured_at, object: reading } }

    @timeline = (log_items + watering_items + moisture_items).sort_by { |item| item[:date] }.reverse
  end

  # GET /plants/new
  def new
    @plant = Plant.new project: current_project, uid: current_project.next_uid
  end

  # GET /plants/1/edit
  def edit
  end

  # POST /plants or /plants.json
  def create
    @plant = Plant.new(plant_params)

    respond_to do |format|
      if @plant.save
        format.html { redirect_to plant_url(@plant), notice: t('plants.messages.create_success') }
        format.json { render :show, status: :created, location: @plant }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @plant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /plants/1 or /plants/1.json
  def update
    respond_to do |format|
      if @plant.update(plant_params)
        format.html { redirect_to plant_url(@plant), notice: t('plants.messages.update_success') }
        format.json { render :show, status: :ok, location: @plant }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @plant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /plants/1 or /plants/1.json
  def destroy
    @plant.destroy

    respond_to do |format|
      format.html { redirect_to plants_url, notice: t("plants.messages.delete_success") }
      format.json { head :no_content }
    end
  end

  def suggest_graphic
    name = params[:name]
    matched_graphic = Plant.match_graphic_for_name(name)
    render json: { graphic: matched_graphic }
  end

  def import

  end
  def process_file
    json = params['plants'].read
    plants = JSON.parse json
    plants = [plants] if plants.class == Hash
    requested = plants.count
    created = plants.map {|j| Plant.create_from_json j, current_project }.map {|p| p.new_record? ? 0 : 1 }.reduce :+
    if created > 0
      redirect_to plants_path, notice: "Successully imported #{created} out of #{requested} plant#{requested > 1 ? 's' : ''}."
    else
      redirect_to plants_path, alert: "No plants imported."
    end
  end

  def create_share
    @plant.generate_share_token!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to plant_path(@plant), notice: t('plants.messages.share_created') }
    end
  end

  def revoke_share
    @plant.revoke_share_token!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to plant_path(@plant), notice: t('plants.messages.share_revoked') }
    end
  end

  def regenerate_share
    @plant.regenerate_share_token!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to plant_path(@plant), notice: t('plants.messages.share_regenerated') }
    end
  end

  def create_view_share
    @plant.generate_view_share_token!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to plant_path(@plant), notice: t('plants.messages.view_share_created', default: 'Viewing link created') }
    end
  end

  def revoke_view_share
    @plant.revoke_view_share_token!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to plant_path(@plant), notice: t('plants.messages.view_share_revoked', default: 'Viewing link revoked') }
    end
  end

  def regenerate_view_share
    @plant.regenerate_view_share_token!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to plant_path(@plant), notice: t('plants.messages.view_share_regenerated', default: 'Viewing link regenerated') }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_plant
      @plant = current_project.plants.find(params[:id])
    end

    def set_project
      if params[:project_id]
        set_current_project Project.find(params[:project_id])
      elsif current_project.nil?
        auto_select_project(current_user)
        redirect_to new_session_path unless current_project
      end
    end

    # Only allow a list of trusted parameters through.
    def plant_params
      params.require(:plant).permit(:name, :uid, :project_id, :zone_id, :location_id, :pot, :archived, :min_watering_freq, :max_watering_freq, :manual_watering_frequency, :graphic, :notifications_enabled, :recipe_id)
    end
end
