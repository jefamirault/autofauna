class RecipeCalculator
  UNITS_TO_ML = {
    'mL'   => 1.0,
    'L'    => 1000.0,
    'cups' => 236.588,
    'oz'   => 29.5735,
    'gal'  => 3785.41,
    'qt'   => 946.353,
    'tsp'  => 4.92892,
    'tbsp' => 14.7868
  }.freeze

  Result = Struct.new(:ingredient_id, :source_name, :amount, :units, :error, keyword_init: true)

  def initialize(recipe, target_volume:, target_units:,
                 reference_volume: 1.0, reference_units: 'gal',
                 target_concentration: nil, reference_concentration: nil)
    @recipe = recipe
    @target_volume = target_volume.to_f
    @target_units = target_units
    @reference_volume = reference_volume.to_f
    @reference_units = reference_units
    @target_concentration = target_concentration&.to_f
    @reference_concentration = reference_concentration&.to_f
  end

  def calculate
    return [] if @recipe.recipe_ingredients.empty?

    vol_ratio = volume_ratio
    conc_ratio = concentration_ratio
    scale = vol_ratio * conc_ratio

    @recipe.recipe_ingredients.includes(:recipe_source).map do |ingredient|
      units = ingredient.units.presence || 'mL'
      scaled = ingredient.amount.to_f * scale
      Result.new(
        ingredient_id: ingredient.id,
        source_name: ingredient.recipe_source.name,
        amount: scaled.round(4),
        units: units,
        error: nil
      )
    end
  end

  def self.supported_units
    UNITS_TO_ML.keys
  end

  private

  def volume_ratio
    target_ml = to_ml(@target_volume, @target_units)
    ref_ml = to_ml(@reference_volume, @reference_units)
    return 1.0 if ref_ml.zero?
    target_ml / ref_ml
  end

  def concentration_ratio
    return 1.0 unless @target_concentration.present? &&
                      @reference_concentration.present? &&
                      @reference_concentration > 0
    @target_concentration / @reference_concentration
  end

  def to_ml(amount, units)
    factor = UNITS_TO_ML[units]
    raise ArgumentError, "Unsupported unit: #{units}" unless factor
    amount * factor
  end
end
