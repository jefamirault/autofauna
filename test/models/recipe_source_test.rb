require "test_helper"

class RecipeSourceTest < ActiveSupport::TestCase
  test "pinned defaults to false" do
    source = RecipeSource.new(project: projects(:one), name: "Unpinned")
    assert_equal false, source.pinned
  end

  test "pinned scope returns only pinned sources" do
    pinned = projects(:one).recipe_sources.pinned
    assert_includes pinned, recipe_sources(:cal_mag)
    assert_not_includes pinned, recipe_sources(:ro_water)
  end
end
