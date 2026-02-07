class PlantsController < ApplicationController
  before_action :authenticate
  before_action :set_project
  before_action :set_plant, only: %i[ show edit update destroy create_share revoke_share regenerate_share ]
  before_action :authorize_viewer, only: [:index, :show]
  before_action :authorize_editor, except: [:index, :show]

  def water
    @plant = Plant.find params[:plant_id]
    redirect_to new_watering_path(plant_id: @plant.id, volume: params[:volume], units: params[:units], notes: params[:notes])
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
    @plants = @q.result(distinct: true)

    # Build location filter buttons with counts
    location_counts = @plants.where.not(location_id: nil).reorder(nil).group(:location_id).count
    no_location_count = @plants.where(location_id: nil).count
    locations_with_plants = Location.where(id: location_counts.keys).order(Arel.sql("LOWER(name)"))
    @location_filters = locations_with_plants.map { |loc| ["#{loc.name} (#{location_counts[loc.id]})", loc.id] }
    @location_filters << ["#{I18n.t('plants.index.no_location')} (#{no_location_count})", nil] if no_location_count > 0

    all_keys = @location_filters.map { |_, id| id&.to_s || "none" }.to_set
    if params[:locations].present?
      @active_location_ids = params[:locations].to_set
      selected_ids = @active_location_ids.include?("none") ? @active_location_ids - Set["none"] : @active_location_ids
      has_none = @active_location_ids.include?("none")
      conditions = []
      conditions << @plants.where(location_id: selected_ids.to_a) if selected_ids.any?
      conditions << @plants.where(location_id: nil) if has_none
      @plants = conditions.reduce { |union, scope| union.or(scope) } if conditions.any?
      @plants = @plants.none if conditions.empty?
    else
      @active_location_ids = all_keys
    end

    @display_mode = params[:display] || "watering"
    if @display_mode == "location"
      grouped = @plants.group_by { |p| p.location&.name }
      no_location = grouped.delete(nil) || []
      @plants_by_location = grouped.sort_by { |name, _| name.downcase }.to_h
      @plants_by_location[I18n.t('plants.index.no_location')] = no_location if no_location.any?
    end

    # Calculate count of plants that need watering (urgent or today)
    @needs_watering_count = @plants.count { |p| [:urgent, :today].include?(p.watering_urgency) }

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

    # Combine log entries and waterings into a single timeline
    log_items = @log_entries.map { |entry| { type: :log_entry, date: entry.timestamp, object: entry } }
    watering_items = @plant.waterings.map { |watering| { type: :watering, date: watering.date.to_datetime, object: watering } }

    @timeline = (log_items + watering_items).sort_by { |item| item[:date] }.reverse
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
    redirect_to plant_path(@plant), notice: t('plants.messages.share_created')
  end

  def revoke_share
    @plant.revoke_share_token!
    redirect_to plant_path(@plant), notice: t('plants.messages.share_revoked')
  end

  def regenerate_share
    @plant.regenerate_share_token!
    redirect_to plant_path(@plant), notice: t('plants.messages.share_regenerated')
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_plant
      @plant = Plant.find(params[:id])
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
      params.require(:plant).permit(:name, :uid, :project_id, :zone_id, :location_id, :pot, :archived, :min_watering_freq, :max_watering_freq, :manual_watering_frequency, :graphic, :notifications_enabled)
    end
end
