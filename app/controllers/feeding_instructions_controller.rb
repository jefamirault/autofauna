class FeedingInstructionsController < ApplicationController
  before_action :authenticate
  before_action :ensure_project
  before_action :require_has_aquarium
  before_action :set_tank
  before_action :set_feeding_instruction, only: [:edit, :update, :destroy]
  before_action :authorize_viewer, only: [:index]
  before_action :authorize_editor, except: [:index]

  def index
    @feeding_instructions = @tank.feeding_instructions
  end

  def new
    @feeding_instruction = @tank.feeding_instructions.build
  end

  def create
    @feeding_instruction = @tank.feeding_instructions.build(feeding_instruction_params)
    if @feeding_instruction.save
      redirect_to tank_path(@tank), notice: 'Feeding instruction added successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @feeding_instruction.update(feeding_instruction_params)
      redirect_to tank_path(@tank), notice: 'Feeding instruction updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @feeding_instruction.destroy
    redirect_to tank_path(@tank), notice: 'Feeding instruction deleted.'
  end

  private

  def set_tank
    @tank = current_project.tanks.find(params[:tank_id])
  end

  def set_feeding_instruction
    @feeding_instruction = @tank.feeding_instructions.find(params[:id])
  end

  def feeding_instruction_params
    params.require(:feeding_instruction).permit(:food_name, :amount, :unit, :frequency, :notes)
  end
end
