class TdsReadingsController < ApplicationController
  before_action :set_tds_reading, only: %i[ show edit update destroy ]
  before_action :authorize_viewer, only: [:index, :show]
  before_action :authorize_editor, except: [:index, :show]

  # GET /tds_readings or /tds_readings.json
  def index
    @tds_readings = current_project.tanks.map(&:tds_readings).reduce(:+)&.sort {|a,b| b.datetime <=> a.datetime}
  end

  # GET /tds_readings/1 or /tds_readings/1.json
  def show
  end

  # GET /tds_readings/new
  def new
    @tds_reading = TdsReading.new datetime: Time.zone.now.to_datetime
  end

  # GET /tds_readings/1/edit
  def edit
  end

  # POST /tds_readings or /tds_readings.json
  def create
    @tds_reading = TdsReading.new(tds_reading_params)

    respond_to do |format|
      if @tds_reading.save
        format.html { redirect_to @tds_reading, notice: "Tds reading was successfully created." }
        format.json { render :show, status: :created, location: @tds_reading }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tds_reading.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tds_readings/1 or /tds_readings/1.json
  def update
    respond_to do |format|
      if @tds_reading.update(tds_reading_params)
        format.html { redirect_to @tds_reading, notice: "Tds reading was successfully updated." }
        format.json { render :show, status: :ok, location: @tds_reading }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tds_reading.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tds_readings/1 or /tds_readings/1.json
  def destroy
    @tds_reading.destroy!

    respond_to do |format|
      format.html { redirect_to tds_readings_path, status: :see_other, notice: "Tds reading was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tds_reading
      @tds_reading = TdsReading.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def tds_reading_params
      params.expect(tds_reading: [ :datetime, :tank_id, :tds ])
    end
end
