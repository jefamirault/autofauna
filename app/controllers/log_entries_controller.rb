class LogEntriesController < ApplicationController
  before_action :set_log_entry, only: %i[ show edit update destroy ]

  def index
    @loggable = Plant.find params[:plant_id]
    @log_entries = @loggable.log_entries.reverse
  end

  def show
    @log_entry = LogEntry.find(params[:id])
    @loggable = @log_entry.loggable
  end

  def new
    @plant = Plant.find(params[:plant_id])
    @log_entry = LogEntry.new loggable_type: 'plant', loggable: @plant, user: current_user
  end

  def edit
    @plant = Plant.find(params[:plant_id])
  end

  def create
    @log_entry = LogEntry.new(log_entry_params)

    respond_to do |format|
      if @log_entry.save
        format.html { redirect_to plant_log_entries_path(plant_id: @log_entry.loggable.id), notice: "Log Entry was successfully created." }
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
  def set_log_entry
    @log_entry = LogEntry.find(params.expect(:id))
  end

  def log_entry_params
    params.expect(log_entry: [ :loggable_type, :loggable_id, :user_id, :description, :timestamp])
  end
end
