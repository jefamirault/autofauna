class Recipe < ApplicationRecord
  belongs_to :project

  has_many :recipe_ingredients, -> { order(:position) }, dependent: :destroy
  has_many :recipe_sources, through: :recipe_ingredients
  has_many :recipe_batches, dependent: :destroy
  has_many :plants
  has_many :waterings

  accepts_nested_attributes_for :recipe_ingredients, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true, uniqueness: { scope: :project_id }

  def self.ransackable_attributes(auth_object = nil)
    %w[id name]
  end

  def to_s
    name
  end
end
