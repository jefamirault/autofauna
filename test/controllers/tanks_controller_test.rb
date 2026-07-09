require "test_helper"

class TanksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @tank = tanks(:one)
    sign_in @user
  end

  test "should get index" do
    get tanks_url
    assert_response :success
  end

  test "should get new" do
    get new_tank_url
    assert_response :success
  end

  test "should create tank" do
    assert_difference("Tank.count") do
      post tanks_url, params: { tank: { description: "New tank", name: "New Tank", project_id: @tank.project_id, location_id: locations(:one).id } }
    end

    assert_redirected_to tank_url(Tank.last)
  end

  test "should show tank" do
    get tank_url(@tank)
    assert_response :success
  end

  test "should get edit" do
    get edit_tank_url(@tank)
    assert_response :success
  end

  test "should update tank" do
    patch tank_url(@tank), params: { tank: { description: @tank.description, name: @tank.name, location_id: locations(:one).id } }
    assert_redirected_to tank_url(@tank)
  end

  test "should create tank with picture" do
    image = fixture_file_upload("plant.png", "image/png")
    assert_difference("Tank.count") do
      post tanks_url, params: { tank: { name: "Tank with photo", project_id: @tank.project_id, picture: image } }
    end

    assert_redirected_to tank_url(Tank.last)
    assert Tank.last.picture.attached?
  end

  test "should attach a picture on update" do
    image = fixture_file_upload("plant.png", "image/png")
    patch tank_url(@tank), params: { tank: { name: @tank.name, picture: image } }
    assert_redirected_to tank_url(@tank)
    assert @tank.reload.picture.attached?
  end

  test "should remove picture when the remove flag is set" do
    @tank.picture.attach(io: File.open(Rails.root.join("test/fixtures/files/plant.png")), filename: "plant.png", content_type: "image/png")
    assert @tank.picture.attached?

    patch tank_url(@tank), params: { tank: { name: @tank.name, remove_picture: "1" } }
    assert_redirected_to tank_url(@tank)
    assert_not @tank.reload.picture.attached?
  end

  test "picture is not removed when the remove flag is set but a replacement is provided" do
    image = fixture_file_upload("plant.png", "image/png")
    patch tank_url(@tank), params: { tank: { name: @tank.name, remove_picture: "1", picture: image } }
    assert_redirected_to tank_url(@tank)
    assert @tank.reload.picture.attached?
  end

  test "should reject a picture with an unsupported content type" do
    file = fixture_file_upload("plant.png", "text/plain")
    patch tank_url(@tank), params: { tank: { name: @tank.name, picture: file } }
    assert_response :unprocessable_entity
    assert_not @tank.reload.picture.attached?
  end

  test "index and show render tank picture" do
    @tank.picture.attach(io: File.open(Rails.root.join("test/fixtures/files/plant.png")), filename: "plant.png", content_type: "image/png")

    get tanks_url
    assert_response :success
    assert_match "resource-card-photo", response.body

    get tank_url(@tank)
    assert_response :success
    assert_match "tank-photo-image", response.body
  end

  test "should destroy tank" do
    assert_difference("Tank.count", -1) do
      delete tank_url(@tank)
    end

    assert_redirected_to tanks_url
  end
end
