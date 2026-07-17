require "test_helper"

class RecipeSourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @source = recipe_sources(:ro_water)
    sign_in @user
  end

  test "update persists pinned" do
    assert_not @source.pinned?
    patch recipe_source_url(@source), params: { recipe_source: { name: @source.name, pinned: "1" } }
    assert @source.reload.pinned?
  end

  test "update can unpin" do
    pinned = recipe_sources(:cal_mag)
    patch recipe_source_url(pinned), params: { recipe_source: { name: pinned.name, pinned: "0" } }
    assert_not pinned.reload.pinned?
  end
end
