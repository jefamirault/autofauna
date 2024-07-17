class WateringsController < ApplicationController
  before_action :set_watering, only: %i[ show edit update destroy ]
  before_action :authenticate

  # GET /waterings or /waterings.json
  def index
    @waterings = Watering.all.order date: :desc
  end

  # GET /waterings/1 or /waterings/1.json
  def show
  end

  # GET /waterings/new
  def new
    @watering = Watering.create plant_id: params[:plant_id], date: Time.zone.now.to_date
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to edit_watering_path(@watering) }
    end
  end

  # GET /waterings/1/edit
  def edit
  end

  # POST /waterings or /waterings.json
  def create
    @watering = Watering.new(watering_params)

    respond_to do |format|
      if @watering.save
        format.html { redirect_to watering_url(@watering), notice: "Watering was successfully created." }
        # format.html { redirect_to plant_water_path(@watering.plant), notice: "Watering was successfully created." }
        format.json { render :show, status: :created, location: @watering }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @watering.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /waterings/1 or /waterings/1.json
  def update
    respond_to do |format|
      if @watering.update(watering_params)
        format.html { redirect_to watering_url(@watering), notice: "Watering was successfully updated." }
        format.json { render :show, status: :ok, location: @watering }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @watering.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /waterings/1 or /waterings/1.json
  def destroy
    @watering.destroy

    respond_to do |format|
      format.html { redirect_to waterings_url, notice: "Watering was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_watering
      @watering = Watering.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def watering_params
      params.require(:watering).permit(:plant_id, :date, :notes)
    end
end
