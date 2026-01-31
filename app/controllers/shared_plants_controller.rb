class SharedPlantsController < ApplicationController
  before_action :set_plant

  def show
    last = @plant.last_watering
    @watering = Watering.new(date: Time.zone.now.to_date, volume: last&.volume, units: last&.units, notes: last&.notes)
    build_timeline
    render layout: 'shared'
  end

  def create_watering
    @watering = @plant.waterings.new(shared_watering_params)

    if @watering.save
      redirect_to shared_plant_path(token: @plant.share_token), notice: t('waterings.messages.create_success')
    else
      build_timeline
      render :show, layout: 'shared', status: :unprocessable_entity
    end
  end

  private

  def set_plant
    @plant = Plant.find_by(share_token: params[:token])
    if @plant.nil? || !@plant.share_enabled?
      render 'not_found', layout: 'shared', status: :not_found and return
    end
  end

  def build_timeline
    @log_entries = @plant.log_entries.reverse
    log_items = @log_entries.map { |entry| { type: :log_entry, date: entry.timestamp, object: entry } }
    watering_items = @plant.waterings.map { |watering| { type: :watering, date: watering.date.to_datetime, object: watering } }
    @timeline = (log_items + watering_items).sort_by { |item| item[:date] }.reverse
    @shared_view = true
  end

  def shared_watering_params
    params.require(:watering).permit(:date, :volume, :units, :notes)
  end
end
