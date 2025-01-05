class SensorTypesController < ApplicationController
  before_action :set_sensor_type, only: %i[ show edit update destroy ]

  # GET /sensor_types or /sensor_types.json
  def index
    @sensor_types = SensorType.all
  end

  # GET /sensor_types/1 or /sensor_types/1.json
  def show
  end

  # GET /sensor_types/new
  def new
    @sensor_type = SensorType.new
  end

  # GET /sensor_types/1/edit
  def edit
  end

  # POST /sensor_types or /sensor_types.json
  def create
    @sensor_type = SensorType.new(sensor_type_params)

    respond_to do |format|
      if @sensor_type.save
        format.html { redirect_to @sensor_type, notice: "Sensor type was successfully created." }
        format.json { render :show, status: :created, location: @sensor_type }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @sensor_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sensor_types/1 or /sensor_types/1.json
  def update
    respond_to do |format|
      if @sensor_type.update(sensor_type_params)
        format.html { redirect_to @sensor_type, notice: "Sensor type was successfully updated." }
        format.json { render :show, status: :ok, location: @sensor_type }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @sensor_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sensor_types/1 or /sensor_types/1.json
  def destroy
    @sensor_type.destroy!

    respond_to do |format|
      format.html { redirect_to sensor_types_path, status: :see_other, notice: "Sensor type was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sensor_type
      @sensor_type = SensorType.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def sensor_type_params
      params.expect(sensor_type: [ :name, :min_temp, :max_temp, :min_humidity, :max_humidity, :accuracy_temp, :resolution_temp, :accuracy_humidity, :resolution_humidity ])
    end
end
