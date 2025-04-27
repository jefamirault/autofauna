class TanksController < ApplicationController
  before_action :set_tank, only: %i[ show edit update destroy ]
  before_action :authorize_viewer, only: [:index, :show]
  before_action :authorize_editor, except: [:index, :show]

  # GET /tanks or /tanks.json
  def index
    @tanks = current_project.tanks
  end

  # GET /tanks/1 or /tanks/1.json
  def show
  end

  # GET /tanks/new
  def new
    @tank = Tank.new
  end

  # GET /tanks/1/edit
  def edit
  end

  # POST /tanks or /tanks.json
  def create
    @tank = Tank.new(tank_params)

    respond_to do |format|
      if @tank.save
        format.html { redirect_to @tank, notice: "Tank was successfully created." }
        format.json { render :show, status: :created, location: @tank }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tank.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tanks/1 or /tanks/1.json
  def update
    respond_to do |format|
      if @tank.update(tank_params)
        format.html { redirect_to @tank, notice: "Tank was successfully updated." }
        format.json { render :show, status: :ok, location: @tank }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tank.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tanks/1 or /tanks/1.json
  def destroy
    @tank.destroy!

    respond_to do |format|
      format.html { redirect_to tanks_path, status: :see_other, notice: "Tank was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tank
      @tank = Tank.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def tank_params
      params.expect(tank: [ :name, :capacity, :capacity_units, :description, :zone_id, :location, :project_id ])
    end
end
