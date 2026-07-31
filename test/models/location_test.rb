require "test_helper"

class LocationTest < ActiveSupport::TestCase
  test "diagram_plants excludes archived plants" do
    location = locations(:one)
    archived = location.plants.first
    archived.update!(archived: true)

    assert_not_includes location.diagram_plants, archived
    assert_equal location.plants.where(archived: false).count, location.diagram_plants.count
  end

  test "layout? is true only once a plant has both coordinates" do
    location = locations(:one)
    plant = location.plants.first

    assert_not location.layout?

    plant.update!(layout_x: 0.4)
    assert_not location.layout?, "half a coordinate pair is not a layout"

    plant.update!(layout_y: 0.6)
    assert location.layout?
  end

  test "layout? ignores archived plants" do
    location = locations(:one)
    plant = location.plants.first
    plant.update!(layout_x: 0.4, layout_y: 0.6, archived: true)

    assert_not location.layout?
  end
end
