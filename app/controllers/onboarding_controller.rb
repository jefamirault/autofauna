class OnboardingController < ApplicationController
  skip_before_action :require_onboarding
  before_action :authenticate
  before_action :ensure_project

  def show
  end

  def update
    has_aquarium = boolean_param(:has_aquarium)
    uses_fertilizer = boolean_param(:water_fertilizer)
    uses_distilled = boolean_param(:water_distilled)

    current_user.update!(
      has_aquarium: has_aquarium,
      use_fertilizers: uses_fertilizer || uses_distilled,
      # Granular tracking preferences default off and turn on the first time
      # the user actually uses the feature (see User#enable_feature!).
      track_waterings: false,
      precise_measurements: false,
      track_soil_moisture: false
    )

    seed_water_sources!(uses_fertilizer: uses_fertilizer, uses_distilled: uses_distilled)

    current_user.complete_onboarding!
    redirect_to onboarding_destination, notice: t('onboarding.completed')
  end

  def skip
    # Minimal setup: everything off, features reveal themselves on first use.
    current_user.update!(User::FEATURE_FLAGS.index_with { false })
    current_user.complete_onboarding!
    redirect_to plants_path
  end

  private

  def boolean_param(key)
    # cast returns nil for missing params; coerce to a real boolean (columns are NOT NULL).
    !!ActiveModel::Type::Boolean.new.cast(params[key])
  end

  def seed_water_sources!(uses_fertilizer:, uses_distilled:)
    if uses_distilled
      current_project.recipe_sources.find_or_create_by(name: "Distilled / RO Water")
    end

    return unless uses_fertilizer

    Array(params[:fertilizers]).map { |n| n.to_s.strip }.reject(&:blank?).uniq.each do |name|
      source = current_project.recipe_sources.find_or_create_by(name: name)
      recipe = current_project.recipes.find_or_create_by(name: name)
      recipe.recipe_ingredients.find_or_create_by(recipe_source: source)
    end
  end

  def onboarding_destination
    case params[:next]
    when "plant" then new_plant_path
    when "tank"  then current_user.has_aquarium? ? new_tank_path : new_plant_path
    else plants_path
    end
  end
end
