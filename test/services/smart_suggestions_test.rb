require "test_helper"

class SmartSuggestionsTest < ActiveSupport::TestCase
  setup do
    @project = Project.create!(name: "SS Test", owner: users(:one))
    @recipe_a = Recipe.create!(name: "Recipe A", project: @project)
    @recipe_b = Recipe.create!(name: "Recipe B", project: @project)
    @recipe_c = Recipe.create!(name: "Recipe C", project: @project)
  end

  test "top returns at most limit items" do
    scorer = ->(_item) { rand }
    svc = SmartSuggestions.new([@recipe_a, @recipe_b, @recipe_c], scorer: scorer, limit: 2)
    assert_equal 2, svc.top.size
  end

  test "top returns highest-scoring items first" do
    scores = { @recipe_a.id => 10, @recipe_b.id => 5, @recipe_c.id => 8 }
    scorer = ->(item) { scores[item.id] }
    svc = SmartSuggestions.new([@recipe_a, @recipe_b, @recipe_c], scorer: scorer, limit: 2)
    top_ids = svc.top.map(&:id)
    assert_equal [@recipe_a.id, @recipe_c.id], top_ids
  end

  test "rest excludes top items" do
    scores = { @recipe_a.id => 10, @recipe_b.id => 5, @recipe_c.id => 8 }
    scorer = ->(item) { scores[item.id] }
    svc = SmartSuggestions.new([@recipe_a, @recipe_b, @recipe_c], scorer: scorer, limit: 2)
    top = svc.top
    rest = svc.rest(top.map(&:id))
    assert_equal 1, rest.size
    assert_equal @recipe_b.id, rest.first.id
  end

  test "recipe_scorer boosts recipes used on active plants" do
    plant = Plant.create!(name: "Test", project: @project, uid: 500)
    PlantRecipe.create!(plant: plant, recipe: @recipe_a, position: 0)
    plant.update_column(:recipe_id, @recipe_a.id)

    scorer = SmartSuggestions.recipe_scorer(@project)
    score_a = scorer.call(@recipe_a)
    score_b = scorer.call(@recipe_b)
    assert score_a > score_b, "Recipe with plant association should score higher"
  end

  test "location_scorer returns a callable" do
    zone = Zone.create!(name: "Zone 1", project: @project)
    loc = Location.create!(name: "Shelf A", zone: zone, project: @project)
    scorer = SmartSuggestions.location_scorer(@project)
    assert_respond_to scorer, :call
    assert_kind_of Numeric, scorer.call(loc)
  end

  test "watering_recipe_scorer boosts plant's own recipes" do
    plant = Plant.create!(name: "Spider", project: @project, uid: 501)
    PlantRecipe.create!(plant: plant, recipe: @recipe_a, position: 0)

    scorer = SmartSuggestions.watering_recipe_scorer(plant)
    score_a = scorer.call(@recipe_a)
    score_b = scorer.call(@recipe_b)
    assert score_a > score_b, "Plant's own recipe should score higher"
  end
end
