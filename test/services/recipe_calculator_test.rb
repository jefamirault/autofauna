require "test_helper"

class RecipeCalculatorTest < ActiveSupport::TestCase
  setup do
    @project = Project.create!(name: "Calculator Test", owner: users(:one))
    @recipe = Recipe.create!(name: "Test Recipe", project: @project)
    @source = RecipeSource.create!(name: "FloraMicro", project: @project)
    @ingredient = RecipeIngredient.create!(
      recipe: @recipe,
      recipe_source: @source,
      amount: 5.0,
      units: "mL",
      position: 1
    )
  end

  test "scales by volume ratio (same units)" do
    calc = RecipeCalculator.new(@recipe, target_volume: 2.0, target_units: "gal",
                                          reference_volume: 1.0, reference_units: "gal")
    results = calc.calculate
    assert_equal 1, results.size
    assert_in_delta 10.0, results.first.amount, 0.001
    assert_equal "mL", results.first.units
    assert_equal "FloraMicro", results.first.source_name
  end

  test "scales by volume ratio (unit conversion)" do
    calc = RecipeCalculator.new(@recipe, target_volume: 4.0, target_units: "qt",
                                          reference_volume: 1.0, reference_units: "gal")
    results = calc.calculate
    # 4 qt = 1 gal, so scale = 1.0
    assert_in_delta 5.0, results.first.amount, 0.01
  end

  test "scales by concentration ratio" do
    calc = RecipeCalculator.new(@recipe, target_volume: 1.0, target_units: "gal",
                                          reference_volume: 1.0, reference_units: "gal",
                                          target_concentration: 800,
                                          reference_concentration: 400)
    results = calc.calculate
    assert_in_delta 10.0, results.first.amount, 0.001
  end

  test "scales by combined volume and concentration" do
    calc = RecipeCalculator.new(@recipe, target_volume: 5.0, target_units: "gal",
                                          reference_volume: 1.0, reference_units: "gal",
                                          target_concentration: 800,
                                          reference_concentration: 400)
    results = calc.calculate
    # 5x volume * 2x concentration = 10x
    assert_in_delta 50.0, results.first.amount, 0.001
  end

  test "returns empty array for recipe with no ingredients" do
    empty_recipe = Recipe.create!(name: "Empty", project: @project)
    calc = RecipeCalculator.new(empty_recipe, target_volume: 1.0, target_units: "gal")
    assert_equal [], calc.calculate
  end

  test "ignores concentration scaling when reference concentration is zero" do
    calc = RecipeCalculator.new(@recipe, target_volume: 1.0, target_units: "gal",
                                          reference_volume: 1.0, reference_units: "gal",
                                          target_concentration: 800,
                                          reference_concentration: 0)
    results = calc.calculate
    assert_in_delta 5.0, results.first.amount, 0.001
  end

  test "ignores concentration scaling when only one concentration provided" do
    calc = RecipeCalculator.new(@recipe, target_volume: 1.0, target_units: "gal",
                                          reference_volume: 1.0, reference_units: "gal",
                                          target_concentration: 800)
    results = calc.calculate
    assert_in_delta 5.0, results.first.amount, 0.001
  end

  test "liters to gallons conversion" do
    calc = RecipeCalculator.new(@recipe, target_volume: 3785.41, target_units: "mL",
                                          reference_volume: 1.0, reference_units: "gal")
    results = calc.calculate
    # 3785.41 mL ≈ 1 gal
    assert_in_delta 5.0, results.first.amount, 0.05
  end

  test "supported_units returns expected unit list" do
    units = RecipeCalculator.supported_units
    assert_includes units, "mL"
    assert_includes units, "L"
    assert_includes units, "gal"
    assert_includes units, "cups"
    assert_includes units, "oz"
    assert_includes units, "qt"
  end
end
