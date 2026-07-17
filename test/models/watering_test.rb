require "test_helper"

class WateringTest < ActiveSupport::TestCase
  setup do
    @plant = plants(:one) # project one
  end

  test "accepts a same-project recipe, source, and batch" do
    w = Watering.new(plant: @plant, watered_at: Time.zone.now, recipe: recipes(:grow), recipe_batch: recipe_batches(:grow_batch))
    assert w.valid?, w.errors.full_messages.to_sentence

    s = Watering.new(plant: @plant, watered_at: Time.zone.now, recipe_source: recipe_sources(:ro_water))
    assert s.valid?, s.errors.full_messages.to_sentence
  end

  test "rejects a recipe from another project" do
    w = Watering.new(plant: @plant, watered_at: Time.zone.now, recipe: recipes(:recipe_p2))
    assert_not w.valid?
    assert_includes w.errors.attribute_names, :recipe
  end

  test "rejects a recipe_source from another project" do
    w = Watering.new(plant: @plant, watered_at: Time.zone.now, recipe_source: recipe_sources(:source_p2))
    assert_not w.valid?
    assert_includes w.errors.attribute_names, :recipe_source
  end

  test "rejects a recipe_batch from another project" do
    w = Watering.new(plant: @plant, watered_at: Time.zone.now, recipe_batch: recipe_batches(:batch_p2))
    assert_not w.valid?
    assert_includes w.errors.attribute_names, :recipe_batch
  end
end
