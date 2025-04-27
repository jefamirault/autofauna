class SensorsController < ApplicationController
  before_action :set_sensor, only: %i[ show edit update destroy ]
  before_action :authorize_viewer, only: [:index, :show]
  before_action :authorize_editor, except: [:index, :show]

  # GET /sensors or /sensors.json
  def index
    @sensors = Sensor.where(project: current_project)
  end

  # GET /sensors/1 or /sensors/1.json
  def show
    @readings = @sensor.hygro_sensor_readings.order datetime: :desc
  end

  # GET /sensors/new
  def new
    @sensor = Sensor.new
  end

  # GET /sensors/1/edit
  def edit
  end

  # POST /sensors or /sensors.json
  def create
    @sensor = Sensor.new(sensor_params)

    respond_to do |format|
      if @sensor.save
        format.html { redirect_to @sensor, notice: "Sensor was successfully created." }
        format.json { render :show, status: :created, location: @sensor }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @sensor.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sensors/1 or /sensors/1.json
  def update
    respond_to do |format|
      if @sensor.update(sensor_params)
        format.html { redirect_to @sensor, notice: "Sensor was successfully updated." }
        format.json { render :show, status: :ok, location: @sensor }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @sensor.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sensors/1 or /sensors/1.json
  def destroy
    @sensor.destroy!

    respond_to do |format|
      format.html { redirect_to sensors_path, status: :see_other, notice: "Sensor was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sensor
      @sensor = Sensor.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def sensor_params
      params.expect(sensor: [ :sensor_type_id, :name, :zone_id, :location, :project_id, :description ])
    end
end
