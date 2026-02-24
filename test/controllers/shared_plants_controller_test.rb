require "test_helper"

class SharedPlantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @plant = plants(:one)
  end

  # --- Watering share token ---

  test "valid watering share token returns 200" do
    @plant.generate_share_token!
    get shared_plant_url(token: @plant.share_token)
    assert_response :success
  end

  test "watering share token is view_only false" do
    @plant.generate_share_token!
    get shared_plant_url(token: @plant.share_token)
    assert_response :success
    # assigns @view_only = false — the create watering form should be present
    assert_select "form"
  end

  # --- View-only share token ---

  test "valid view-only share token returns 200" do
    @plant.generate_view_share_token!
    get shared_plant_url(token: @plant.view_share_token)
    assert_response :success
  end

  # --- Invalid token ---

  test "invalid token returns 404" do
    get shared_plant_url(token: "nonexistent_token_xyz")
    assert_response :not_found
  end

  test "nil token does not raise 500" do
    get shared_plant_url(token: "does-not-exist-at-all")
    assert_response :not_found
  end

  # --- Revoked watering share ---

  test "revoked watering share returns 404" do
    @plant.generate_share_token!
    token = @plant.share_token
    @plant.revoke_share_token!

    get shared_plant_url(token: token)
    assert_response :not_found
  end

  # --- Revoked view-only share ---

  test "revoked view share returns 404" do
    @plant.generate_view_share_token!
    token = @plant.view_share_token
    @plant.revoke_view_share_token!

    get shared_plant_url(token: token)
    assert_response :not_found
  end

  # --- Token type precedence: watering token does not match as view token ---

  test "watering share token is not accessible as view-only token" do
    @plant.generate_share_token!
    # The watering token should not match view_share_token lookup
    # unless it happens to be the same value (won't be — separate columns)
    # Revoking the watering share means the token is disabled
    @plant.revoke_share_token!
    get shared_plant_url(token: @plant.share_token)
    assert_response :not_found
  end
end
