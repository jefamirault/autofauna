class MaintenanceLogsController < ApplicationController
  before_action :authenticate
  before_action :ensure_project
  before_action :set_tank
  before_action :set_equipment_item
  before_action :set_maintenance_log, only: [:show, :edit, :update, :destroy]
  before_action :authorize_viewer, only: [:index, :show]
  before_action :authorize_editor, except: [:index, :show]

  def index
    @maintenance_logs = @equipment_item.maintenance_logs.recent
  end

  def show
  end

  def new
    @maintenance_log = @equipment_item.maintenance_logs.build(performed_at: Time.current)
  end

  def create
    @maintenance_log = @equipment_item.maintenance_logs.build(maintenance_log_params)
    if @maintenance_log.save
      redirect_to tank_equipment_path(@tank, @equipment_item), notice: 'Maintenance logged successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @maintenance_log.update(maintenance_log_params)
      redirect_to tank_equipment_path(@tank, @equipment_item), notice: 'Maintenance log updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @maintenance_log.destroy
    redirect_to tank_equipment_path(@tank, @equipment_item), notice: 'Maintenance log deleted.'
  end

  private

  def set_tank
    @tank = current_project.tanks.find(params[:tank_id])
  end

  def set_equipment_item
    @equipment_item = @tank.equipment.find(params[:equipment_id])
  end

  def set_maintenance_log
    @maintenance_log = @equipment_item.maintenance_logs.find(params[:id])
  end

  def maintenance_log_params
    params.require(:maintenance_log).permit(:performed_at, :notes)
  end
end
