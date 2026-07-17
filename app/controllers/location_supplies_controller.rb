class LocationSuppliesController < ApplicationController
  before_action :authenticate
  before_action :ensure_project
  before_action :require_use_fertilizers
  before_action :set_location
  before_action :set_location_supply, only: %i[adjust destroy]
  before_action :authorize_editor

  # POST /locations/:location_id/location_supplies
  # Stock a supply at this location, or add to it if it already exists.
  def create
    supplyable = resolve_supplyable
    if supplyable.nil?
      return redirect_to location_path(@location),
                         alert: "That supply isn't available in this project."
    end

    units = permitted_units(params[:units]) || "gal"
    @location_supply = @location.location_supplies.find_or_initialize_by(
      supplyable_type: supplyable.class.name, supplyable_id: supplyable.id
    )
    @location_supply.quantity_units ||= units
    @location_supply.save! if @location_supply.new_record?
    @location_supply.add!(params[:amount], units, user: current_user, note: params[:note])

    redirect_to location_path(@location), notice: "Added to #{@location.name} supply."
  end

  # PATCH /locations/:location_id/location_supplies/:id/adjust
  def adjust
    units = permitted_units(params[:units]) || @location_supply.quantity_units

    case params[:adjust_action]
    when "add"
      @location_supply.add!(params[:amount], units, user: current_user, note: params[:note])
    when "remove"
      @location_supply.remove!(params[:amount], units, user: current_user, note: params[:note])
    when "deplete"
      @location_supply.deplete!(user: current_user, note: params[:note])
    end

    redirect_to location_path(@location), notice: "Supply updated."
  end

  # DELETE /locations/:location_id/location_supplies/:id
  def destroy
    @location_supply.destroy!
    redirect_to location_path(@location), notice: "Supply removed."
  end

  private

  def set_location
    @location = current_project.locations.find(params.expect(:location_id))
  end

  def set_location_supply
    @location_supply = @location.location_supplies.find(params.expect(:id))
  end

  # Resolve the supplyable ONLY from this project's own sources/batches so a supply from another
  # project can never be attached (multi-tenant mass-assignment guard). Expects "Type:id".
  def resolve_supplyable
    type, id = params[:supplyable].to_s.split(":", 2)
    return nil unless LocationSupply::SUPPLYABLE_TYPES.include?(type)

    scope = type == "RecipeSource" ? current_project.recipe_sources : current_project.recipe_batches
    scope.find_by(id: id)
  end

  def permitted_units(units)
    LocationSupply.quantity_units.key?(units.to_s) ? units.to_s : nil
  end
end
