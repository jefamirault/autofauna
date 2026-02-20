class SoilMoistureReadingsController < ApplicationController
  before_action :authorize_viewer, only: [:index]
  before_action :authorize_editor, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_plant
  before_action :set_soil_moisture_reading, only: [:edit, :update, :destroy]

  def index
    @soil_moisture_readings = @plant.soil_moisture_readings.recent
  end

  def new
    @soil_moisture_reading = @plant.soil_moisture_readings.new
  end

  def create
    @soil_moisture_reading = @plant.soil_moisture_readings.new(soil_moisture_reading_params)
    @soil_moisture_reading.timing = :standalone

    if @soil_moisture_reading.save
      redirect_to plant_path(@plant), notice: t('soil_moisture_readings.create_success')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @soil_moisture_reading.update(soil_moisture_reading_params)
      redirect_to plant_path(@plant), notice: t('soil_moisture_readings.update_success')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @soil_moisture_reading.destroy
    redirect_to plant_path(@plant), notice: t('soil_moisture_readings.delete_success')
  end

  private

  def set_plant
    @plant = current_project.plants.find(params[:plant_id])
  end

  def set_soil_moisture_reading
    @soil_moisture_reading = @plant.soil_moisture_readings.find(params[:id])
  end

  def soil_moisture_reading_params
    if current_project.moisture_measurement_type == 'numeric'
      params.require(:soil_moisture_reading).permit(:measured_at, :value_numeric, :notes)
    else
      params.require(:soil_moisture_reading).permit(:measured_at, :value_categorical, :notes)
    end
  end
end
