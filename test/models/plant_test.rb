require "test_helper"
require 'byebug'

class PlantTest < ActiveSupport::TestCase
  test 'When watering a plant, update watering dates based on freq: date_last_watering, date_min_watering, date_max_watering' do
    params = {
      min: 5.days,
      max: 7.days
    }

    project = Project.create name: 'A Project'
    plant = Plant.new(name: "A Plant", min_watering_freq: 5, max_watering_freq: 7, project: project)
    assert plant.save
    watering = Watering.create plant: plant, date: Time.zone.now.to_date
    plant.reload
    assert_equal watering.date + params[:min], plant.date_min_watering
  end
end
