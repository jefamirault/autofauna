class SmartSuggestions
  Suggestion = Struct.new(:id, :label, :score, keyword_init: true)

  def initialize(collection, scorer:, limit: 3)
    @collection = collection
    @scorer = scorer
    @limit = limit
  end

  def top
    scored = @collection.map do |item|
      score = @scorer.call(item)
      Suggestion.new(id: item.id, label: item.to_s, score: score)
    end
    scored.sort_by { |s| -s.score }.first(@limit)
  end

  def rest(top_ids)
    @collection.reject { |item| top_ids.include?(item.id) }
  end

  # ─── Pre-built scorers ─────────────────────────────────────────────────────

  # Most recently used location (by last plant added)
  def self.location_scorer(project)
    recent_location_ids = project.plants
      .where.not(location_id: nil)
      .order(created_at: :desc)
      .limit(50)
      .pluck(:location_id)

    usage_counts = recent_location_ids.tally
    max_count = usage_counts.values.max || 1

    recency_bonus = {}
    recent_location_ids.each_with_index do |loc_id, idx|
      recency_bonus[loc_id] ||= (50 - idx).to_f / 50
    end

    ->(location) {
      count_score = (usage_counts[location.id] || 0).to_f / max_count
      recency_bonus[location.id].to_f + count_score
    }
  end

  # Most commonly used recipes (by active plant count, then recent batch count)
  def self.recipe_scorer(project)
    plant_counts = project.plants.where.not(recipe_id: nil).group(:recipe_id).count
    batch_counts = project.recipe_batches.active.group(:recipe_id).count
    max_plants = plant_counts.values.max || 1

    ->(recipe) {
      plant_score = (plant_counts[recipe.id] || 0).to_f / max_plants
      batch_bonus = batch_counts[recipe.id].present? ? 0.5 : 0.0
      plant_score + batch_bonus
    }
  end

  # Most commonly mixed recipes (by batch count, recency-weighted)
  def self.recipe_batch_scorer(project)
    batches = project.recipe_batches.order(mixed_on: :desc).limit(50)
    recipe_counts = batches.group_by(&:recipe_id).transform_values(&:count)
    max_count = recipe_counts.values.max || 1

    recent_recipe_ids = batches.pluck(:recipe_id).uniq
    recency_bonus = recent_recipe_ids.each_with_index.to_h { |rid, idx| [rid, (10 - idx).to_f / 10] }

    has_active_batch = project.recipe_batches.active.pluck(:recipe_id).to_set

    ->(recipe) {
      count_score = (recipe_counts[recipe.id] || 0).to_f / max_count
      recency = recency_bonus[recipe.id].to_f
      # Boost recipes with NO active batch (next to be mixed)
      no_batch_bonus = has_active_batch.include?(recipe.id) ? 0.0 : 0.3
      count_score + recency + no_batch_bonus
    }
  end

  # Most recent active batches for a given recipe
  def self.batch_scorer_for_recipe(recipe_id)
    ->(batch) {
      return 0.0 unless batch.recipe_id == recipe_id
      days_old = batch.mixed_on ? [(Date.current - batch.mixed_on).to_i, 0].max : 365
      [1.0 - days_old.to_f / 365, 0.0].max
    }
  end

  # Plant's own recipes at top, then previously-used recipes for this plant
  def self.watering_recipe_scorer(plant)
    plant_recipe_ids = plant.plant_recipes.pluck(:recipe_id).to_set
    recent_recipe_ids = plant.waterings.where.not(recipe_id: nil)
                             .order(watered_at: :desc).limit(20).pluck(:recipe_id)
    recency = recent_recipe_ids.each_with_index.to_h { |rid, idx| [rid, (20 - idx).to_f / 20] }

    ->(recipe) {
      primary_bonus = plant_recipe_ids.include?(recipe.id) ? 2.0 : 0.0
      primary_bonus + recency[recipe.id].to_f
    }
  end
end
