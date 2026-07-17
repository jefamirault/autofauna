require "test_helper"

class WateringsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @watering = waterings(:one)
    sign_in @user
  end

  test "should get index" do
    get waterings_url
    assert_response :success
  end

  test "index should sort waterings newest first" do
    plant = plants(:one)
    Watering.create!(plant: plant, watered_at: 3.days.ago, notes: "older_watering_marker")
    Watering.create!(plant: plant, watered_at: 1.day.ago, notes: "newer_watering_marker")

    get waterings_url
    assert_response :success

    body = response.body
    newer_pos = body.index("newer_watering_marker")
    older_pos = body.index("older_watering_marker")
    assert newer_pos < older_pos, "Expected newest watering to appear before oldest watering"
  end

  test "should get new" do
    get new_watering_url(plant_id: @watering.plant_id)
    assert_response :success
  end

  test "should create watering" do
    assert_difference("Watering.count") do
      post waterings_url, params: { watering: { watered_at: Time.zone.now, notes: "Test watering", plant_id: @watering.plant_id } }
    end

    assert_redirected_to plant_url(@watering.plant)
  end

  test "should show watering" do
    get watering_url(@watering)
    assert_response :success
  end

  test "should get edit" do
    get edit_watering_url(@watering)
    assert_response :success
  end

  test "should update watering" do
    patch watering_url(@watering), params: { watering: { watered_at: @watering.watered_at, notes: @watering.notes, plant_id: @watering.plant_id } }
    assert_redirected_to plant_url(@watering.plant)
  end

  test "should destroy watering" do
    assert_difference("Watering.count", -1) do
      delete watering_url(@watering)
    end

    assert_redirected_to plant_url(@watering.plant)
  end

  # ─── Fertilizer picker (#113) ──────────────────────────────────────────────

  test "create with recipe and batch persists both ids (data fidelity)" do
    post waterings_url, params: { watering: {
      watered_at: Time.zone.now, plant_id: plants(:one).id,
      recipe_id: recipes(:grow).id, recipe_batch_id: recipe_batches(:grow_batch).id
    } }
    w = Watering.order(:created_at).last
    assert_equal recipes(:grow).id, w.recipe_id
    assert_equal recipe_batches(:grow_batch).id, w.recipe_batch_id
  end

  test "create with a source persists the source and no recipe/batch" do
    post waterings_url, params: { watering: {
      watered_at: Time.zone.now, plant_id: plants(:one).id,
      recipe_source_id: recipe_sources(:ro_water).id
    } }
    w = Watering.order(:created_at).last
    assert_equal recipe_sources(:ro_water).id, w.recipe_source_id
    assert_nil w.recipe_id
    assert_nil w.recipe_batch_id
  end

  test "create with a cross-project recipe is rejected" do
    assert_no_difference("Watering.count") do
      post waterings_url, params: { watering: {
        watered_at: Time.zone.now, plant_id: plants(:one).id,
        recipe_id: recipes(:recipe_p2).id
      } }
    end
    assert_response :unprocessable_entity
  end

  test "new form renders pinned items as chips and unpinned recipes only in the panel" do
    get new_watering_url(plant_id: plants(:one).id)
    assert_response :success

    assert_select ".fertilizer-picker"
    assert_select ".suggestion-chip[data-kind='none']"
    # Pins define the shortlist.
    assert_select ".suggestion-chip[data-kind='recipe'][data-id='#{recipes(:pinned_grow).id}']"
    assert_select ".suggestion-chip[data-kind='source'][data-id='#{recipe_sources(:cal_mag).id}']"
    # The unpinned recipe is absent from the chip row but present in the search panel.
    assert_select ".suggestion-chip[data-kind='recipe'][data-id='#{recipes(:grow).id}']", count: 0
    assert_select ".fertilizer-picker-row[data-kind='recipe'][data-id='#{recipes(:grow).id}']"
  end

  test "no-pins project falls back to smart-suggestion chips" do
    sign_in users(:two)
    get new_watering_url(plant_id: plants(:plant_p2).id)
    assert_response :success

    assert_select ".suggestion-chip[data-kind='recipe'][data-id='#{recipes(:recipe_p2).id}']"
    assert_select ".suggestion-chip[data-kind='source'][data-id='#{recipe_sources(:source_p2).id}']"
  end

  test "edit round-trips an unpinned recipe with a since-deactivated batch" do
    inactive = projects(:one).recipe_batches.create!(recipe: recipes(:grow), tds: 700, active: false)
    w = plants(:one).waterings.create!(watered_at: Time.zone.now, recipe: recipes(:grow), recipe_batch: inactive)

    get edit_watering_url(w)
    assert_response :success
    # The unpinned selection shows as a selected chip, and its inactive batch is still offered.
    assert_select ".suggestion-chip[data-kind='recipe'][data-id='#{recipes(:grow).id}'].selected"
    assert_includes @response.body, "(inactive)"

    # Saving without changes preserves all three ids.
    patch watering_url(w), params: { watering: {
      watered_at: w.watered_at, plant_id: w.plant_id,
      recipe_id: recipes(:grow).id, recipe_batch_id: inactive.id
    } }
    w.reload
    assert_equal recipes(:grow).id, w.recipe_id
    assert_equal inactive.id, w.recipe_batch_id
  end
end
