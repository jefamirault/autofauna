require "test_helper"

class OnboardingControllerTest < ActionDispatch::IntegrationTest
  test "non-onboarded user is redirected to onboarding" do
    sign_in users(:fresh)
    get plants_url
    assert_redirected_to onboarding_path
  end

  test "non-onboarded user can view onboarding" do
    sign_in users(:fresh)
    get onboarding_url
    assert_response :success
  end

  test "non-onboarded user can still access settings" do
    sign_in users(:fresh)
    get settings_url
    assert_response :success
  end

  test "non-onboarded user can log out" do
    sign_in users(:fresh)
    delete session_url
    assert_redirected_to new_session_path
  end

  test "tap-only sets up no sources and disables fertilizer features" do
    user = users(:fresh)
    sign_in user

    assert_no_difference -> { RecipeSource.count } do
      patch onboarding_url, params: { water_tap: "1" }
    end
    assert_redirected_to plants_path

    user.reload
    assert user.onboarding_completed?
    assert_not user.use_fertilizers?
    assert_not user.has_aquarium?
    # Granular tracking preferences default off (enabled on first use).
    assert_not user.track_waterings?
    assert_not user.precise_measurements?
    assert_not user.track_soil_moisture?
  end

  test "fertilizer answers create a source and starter recipe per name" do
    user = users(:fresh)
    sign_in user
    project = projects(:project_fresh)

    patch onboarding_url, params: {
      water_tap: "1",
      water_fertilizer: "1",
      fertilizers: ["Miracle-Gro", "Fish Emulsion", ""]
    }

    user.reload
    assert user.use_fertilizers?
    ["Miracle-Gro", "Fish Emulsion"].each do |name|
      source = project.recipe_sources.find_by(name: name)
      assert source, "expected source #{name}"
      recipe = project.recipes.find_by(name: name)
      assert recipe, "expected recipe #{name}"
      assert recipe.recipe_sources.include?(source), "recipe #{name} should reference its source"
    end
  end

  test "distilled answer adds a water source and enables fertilizer features" do
    user = users(:fresh)
    sign_in user
    project = projects(:project_fresh)

    patch onboarding_url, params: { water_tap: "1", water_distilled: "1" }

    user.reload
    assert user.use_fertilizers?
    assert project.recipe_sources.exists?(name: "Distilled / RO Water")
  end

  test "aquarium answer with tank choice redirects to new tank" do
    user = users(:fresh)
    sign_in user

    patch onboarding_url, params: { has_aquarium: "1", water_tap: "1", next: "tank" }

    user.reload
    assert user.has_aquarium?
    assert_redirected_to new_tank_path
  end

  test "plant choice redirects to new plant" do
    sign_in users(:fresh)
    patch onboarding_url, params: { water_tap: "1", next: "plant" }
    assert_redirected_to new_plant_path
  end

  test "skipping onboarding completes it with all features off" do
    user = users(:fresh)
    sign_in user

    post skip_onboarding_url
    assert_redirected_to plants_path

    user.reload
    assert user.onboarding_completed?
    User::FEATURE_FLAGS.each do |flag|
      assert_not user.public_send("#{flag}?"), "expected #{flag} to be off after skip"
    end
  end

  test "onboarded user is not redirected" do
    sign_in users(:one)
    get plants_url
    assert_response :success
  end

  test "unauthenticated user is redirected to login" do
    get onboarding_url
    assert_redirected_to new_session_path
  end
end
