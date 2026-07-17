require "test_helper"

class RecipesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @recipe = recipes(:grow)
    sign_in @user
  end

  test "update persists pinned" do
    assert_not @recipe.pinned?
    patch recipe_url(@recipe), params: { recipe: { name: @recipe.name, pinned: "1" } }
    assert @recipe.reload.pinned?
  end

  test "update can unpin" do
    pinned = recipes(:pinned_grow)
    patch recipe_url(pinned), params: { recipe: { name: pinned.name, pinned: "0" } }
    assert_not pinned.reload.pinned?
  end
end
