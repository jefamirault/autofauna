class PlantsController < ApplicationController
  before_action :set_project
  before_action :set_plant, only: %i[ show edit update destroy ]
  before_action :authenticate, only: [:new]
  before_action :authorize_viewer, only: [:index, :show]
  before_action :authorize_editor, except: [:index, :show]

  def water
    @plant = Plant.find params[:plant_id]
    redirect_to new_watering_path(plant_id: @plant.id)
  end

  # GET /plants or /plants.json
  def index
    active = current_project.plants.where(archived: false).reject {|p| p.scheduled_watering.nil? }
    if active.size > 0
      by_next = active.sort do |a,b|
        if a.scheduled_watering == b.scheduled_watering
          if a.location == b.location
            a.uid <=> b.uid
          else
            a.location <=> b.location
          end
        else
          a.scheduled_watering <=> b.scheduled_watering
        end
      end

      today = Time.zone.now.to_date
      cutoff = by_next.find_index {|p| p.scheduled_watering > today} || by_next.count

      @needs_water = by_next.take cutoff
      @upcoming = by_next.drop cutoff

      # sort by last watered, then by location
      by_last = active.sort do |a,b|
        if a.last_watering == b.last_watering
          a.location <=> b.location
        elsif a.last_watering.nil?
          -1
        elsif b.last_watering.nil?
          1
        else
          b.last_watering <=> a.last_watering
        end
      end

      cutoff = by_last.find_index {|p| p.last_watering && p.last_watering < today} || by_last.size
      @watered_today = by_last.take(cutoff).reject {|p| p.last_watering.nil?}.sort do |a,b|
        b.waterings.last.updated_at <=> a.waterings.last.updated_at
      end
      @recently = by_last.drop(cutoff).reject {|p| p.last_watering.nil? || p.last_watering < Time.zone.now.to_date - 1.week}
    end

    @unscheduled = current_project.plants.where(scheduled_watering: nil, archived: false)

    respond_to do |format|
      format.json { @plants = current_project.plants }
      format.html
    end
  end

  # GET /plants/1 or /plants/1.json
  def show
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_plant
      @plant = Plant.find(params[:id])
    end

    def set_project
      if params[:project_id]
        set_current_project Project.find(params[:project_id])
      end
    end

    # Only allow a list of trusted parameters through.
    def plant_params
      params.require(:plant).permit(:name, :uid, :project_id, :location, :pot, :archived, :watering_frequency, :manual_watering_frequency, :scheduled_watering)
    end
end
