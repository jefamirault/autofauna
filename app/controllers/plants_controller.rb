class PlantsController < ApplicationController
  before_action :set_plant, only: %i[ show edit update destroy ]
  before_action :authenticate

  def water
    @plant = Plant.find params[:plant_id]
    redirect_to new_watering_path(plant_id: @plant.id)
  end

  # GET /plants or /plants.json
  def index
    active = Plant.where(archived: false).reject {|p| p.scheduled_watering.nil? || p.last_watering.nil?}
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
    cutoff = by_next.find_index {|p| p.scheduled_watering > today}
    @needs_water = by_next.take cutoff
    @upcoming = by_next.drop cutoff

    by_last = active.sort do |a,b|
      if a.last_watering == b.last_watering
        a.location <=> b.location
      else
        b.last_watering <=> a.last_watering
      end
    end

    cutoff = by_last.find_index {|p| p.last_watering < today} || by_last.size
    @watered_today = by_last.take cutoff
    @recently = by_last.drop(cutoff).reject {|p| p.last_watering < Time.zone.now.to_date - 1.week}

    @unscheduled = Plant.where(scheduled_watering: nil, archived: false)
  end

  # GET /plants/1 or /plants/1.json
  def show
  end

  # GET /plants/new
  def new
    @plant = Plant.new
  end

  # GET /plants/1/edit
  def edit
  end

  # POST /plants or /plants.json
  def create
    @plant = Plant.new(plant_params)

    respond_to do |format|
      if @plant.save
        format.html { redirect_to plant_url(@plant), notice: "Plant was successfully created." }
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
        format.html { redirect_to plant_url(@plant), notice: "Plant was successfully updated." }
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
      format.html { redirect_to plants_url, notice: "Plant was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_plant
      @plant = Plant.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def plant_params
      params.require(:plant).permit(:name, :uid, :location, :pot, :archived, :watering_frequency, :manual_watering_frequency, :scheduled_watering)
    end
end
