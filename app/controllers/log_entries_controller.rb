class LogEntriesController < ApplicationController
  before_action :authenticate
  before_action :ensure_project
  before_action :set_plant, only: %i[ index new edit ]
  before_action :set_log_entry, only: %i[ show edit update destroy ]
  before_action :authorize_viewer, only: [:index, :show]
  before_action :authorize_editor, except: [:index, :show]

  def index
    @loggable = @plant
    @log_entries = @loggable.log_entries.reverse
  end

  def show
    @loggable = @log_entry.loggable
  end

  def new
    @log_entry = LogEntry.new loggable_type: 'plant', loggable: @plant, user: current_user
  end

  def edit
  end

  def create
    @log_entry = LogEntry.new(log_entry_params)

    respond_to do |format|
      if @log_entry.save
        format.html { redirect_to @log_entry.loggable, notice: "Log Entry was successfully created." }
        format.json { render :show, status: :created, log_entry: @log_entry }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @log_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @log_entry.update(log_entry_params)
        format.html { redirect_to @log_entry.loggable, notice: "Log Entry was successfully updated." }
        format.json { render :show, status: :ok, log_entry: @log_entry }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @log_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @log_entry.destroy!

    respond_to do |format|
      format.html { redirect_to plant_log_entries_path(plant_id: @log_entry.loggable.id), status: :see_other, notice: "Log Entry was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_plant
    @plant = current_project.plants.find(params[:plant_id])
  end

  def set_log_entry
    plant = @plant || current_project.plants.find(params[:plant_id])
    @log_entry = plant.log_entries.find(params.expect(:id))
    @plant ||= plant
  end

  def log_entry_params
    params.expect(log_entry: [ :loggable_type, :loggable_id, :user_id, :description, :timestamp])
  end
end
