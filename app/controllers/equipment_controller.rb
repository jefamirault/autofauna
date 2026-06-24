class EquipmentController < ApplicationController
  before_action :authenticate
  before_action :ensure_project
  before_action :require_has_aquarium
  before_action :set_tank
  before_action :set_equipment_item, only: [:show, :edit, :update, :destroy]
  before_action :authorize_viewer, only: [:index, :show]
  before_action :authorize_editor, except: [:index, :show]

  def index
    @equipment_items = @tank.equipment
  end

  def show
    @maintenance_logs = @equipment_item.maintenance_logs.recent
  end

  def new
    @equipment_item = @tank.equipment.build
  end

  def create
    @equipment_item = @tank.equipment.build(equipment_params)
    if @equipment_item.save
      redirect_to tank_path(@tank), notice: 'Equipment added successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @equipment_item.update(equipment_params)
      redirect_to tank_equipment_path(@tank, @equipment_item), notice: 'Equipment updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @equipment_item.destroy
    redirect_to tank_path(@tank), notice: 'Equipment deleted.'
  end

  private

  def set_tank
    @tank = current_project.tanks.find(params[:tank_id])
  end

  def set_equipment_item
    @equipment_item = @tank.equipment.find(params[:id])
  end

  def equipment_params
    params.require(:equipment).permit(:name, :maintenance_instructions, :maintenance_interval_days)
  end
end
