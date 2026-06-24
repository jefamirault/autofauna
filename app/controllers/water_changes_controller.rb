class WaterChangesController < ApplicationController
  before_action :authenticate
  before_action :ensure_project
  before_action :require_has_aquarium
  before_action :set_tank
  before_action :set_water_change, only: [:edit, :update, :destroy]
  before_action :authorize_viewer, only: [:index]
  before_action :authorize_editor, except: [:index]

  def index
    @water_changes = @tank.water_changes.recent
  end

  def new
    @water_change = @tank.water_changes.build(changed_at: Time.current)
  end

  def create
    @water_change = @tank.water_changes.build(water_change_params)
    if @water_change.save
      redirect_to tank_path(@tank), notice: 'Water change logged successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @water_change.update(water_change_params)
      redirect_to tank_path(@tank), notice: 'Water change updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @water_change.destroy
    redirect_to tank_path(@tank), notice: 'Water change deleted.'
  end

  private

  def set_tank
    @tank = current_project.tanks.find(params[:tank_id])
  end

  def set_water_change
    @water_change = @tank.water_changes.find(params[:id])
  end

  def water_change_params
    params.require(:water_change).permit(:changed_at, :percentage, :volume, :volume_units, :notes)
  end
end
