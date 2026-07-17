require "test_helper"

class RecipeTest < ActiveSupport::TestCase
  test "pinned defaults to false" do
    recipe = Recipe.new(project: projects(:one), name: "Unpinned")
    assert_equal false, recipe.pinned
  end

  test "pinned scope returns only pinned recipes" do
    pinned = projects(:one).recipes.pinned
    assert_includes pinned, recipes(:pinned_grow)
    assert_not_includes pinned, recipes(:grow)
  end
end
