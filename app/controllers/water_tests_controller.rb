class WaterTestsController < ApplicationController
  before_action :set_tank
  before_action :set_water_test, only: [:show, :edit, :update, :destroy]

  def index
    @water_tests = @tank.water_tests.recent.includes(:tank)
  end

  def show
  end

  def new
    @water_test = @tank.water_tests.build
  end

  def create
    @water_test = @tank.water_tests.build(water_test_params)

    if @water_test.save
      redirect_to tank_path(@tank), notice: 'Water test recorded successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @water_test.update(water_test_params)
      redirect_to tank_path(@tank, @water_test), notice: 'Water test updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @water_test.destroy
    redirect_to tank_path(@tank), notice: 'Water test deleted.'
  end

  private

  def set_tank
    @tank = Tank.find(params[:tank_id])
  end

  def set_water_test
    @water_test = @tank.water_tests.find(params[:id])
  end

  def water_test_params
    params.require(:water_test).permit(
      :tested_at, :notes,
      :ph, :tds, :temperature, :temperature_unit,
      :nitrate, :nitrite, :ammonia, :kh, :gh
    )
  end
end