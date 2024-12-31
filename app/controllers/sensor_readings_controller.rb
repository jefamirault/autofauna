class SensorReadingsController < ApplicationController
  before_action :authorize_viewer, only: [:readings]
  before_action :set_project

  def transmit
    required_params = %w(project_id API_KEY temp humidity)
    params_present = required_params.map {|k| !params[k].nil? }.reduce :&
    if params_present
      project = Project.find params['project_id']
      sensor = Sensor.find params[:sensor_id]
      if project && !project.api_key.nil? && params['API_KEY'] == project.api_key
        r = HygroSensorReading.new temperature: params['temp'], humidity: params['humidity'], datetime: Time.zone.now, project: project, sensor: sensor
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
    @readings = HygroSensorReading.where(project_id: current_project.id)&.order datetime: :desc
  end

  private
  def set_project
    if params[:project_id]
      set_current_project Project.find(params[:project_id])
    elsif current_project.nil?
      redirect_to projects_path
    end
  end
end
