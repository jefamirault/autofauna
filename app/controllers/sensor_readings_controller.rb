class SensorReadingsController < ApplicationController
  skip_before_action :require_onboarding, only: [:transmit]
  # transmit is the public sensor endpoint (authenticates via API key against the
  # project_id param); every other action is a normal, session-scoped web action.
  before_action :authenticate, except: [:transmit]
  before_action :ensure_project, except: [:transmit]
  before_action :authorize_viewer, only: [:readings]
  before_action :authorize_editor, only: [:import, :process_file]

  def transmit
    required_params = %w(project_id API_KEY temp humidity)
    params_present = required_params.map {|k| !params[k].nil? }.reduce :&
    if params_present
      project = Project.find_by id: params['project_id']
      sensor = project&.sensors&.find_by(id: params[:sensor_id])
      if project && !project.api_key.nil? && params['API_KEY'] == project.api_key
        r = HygroSensorReading.new temperature: params['temp'], humidity: params['humidity'], datetime: Time.zone.now, project: project, sensor: sensor, error: params['error']
        if r.save
        #   success
          render html: "<h1>Hello Programmer!</h1><h2><code>#{r}</code></h2>".html_safe, layout: false
        else
          render html: '<h1>Malformed Request</h1>'.html_safe
        end
      else
        render html: '<h1>Hello Arduino!</h1>'.html_safe, layout: false
      end
    else
      render html: '<h1>Unauthorized</h1>'.html_safe
    end
  end

  def readings
    @readings = HygroSensorReading.where(project_id: current_project.id)&.order(datetime: :desc).first 1000
  end

  def import

  end
  def process_file
    json = params['sensor_readings'].read
    sensor_readings = JSON.parse json
    sensor_readings = [sensor_readings] if sensor_readings.class == Hash
    requested = sensor_readings.count
    created = sensor_readings.map {|j| HygroSensorReading.create_from_json j, current_project }.map {|p| p.new_record? ? 0 : 1 }.reduce :+
    if created > 0
      redirect_to sensor_readings_path, notice: "Successfully imported #{created} out of #{requested} sensor reading#{requested > 1 ? 's' : ''}."
    else
      redirect_to sensor_readings_path, alert: "No sensor readings imported."
    end
  end
end
