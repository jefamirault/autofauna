class Project < ApplicationRecord
  belongs_to :owner, foreign_key: 'owner_id', class_name: 'User'

  has_many :collaborations, dependent: :destroy
  has_many :collaborators, through: :collaborations, source: 'user'

  has_many :plants, dependent: :destroy
  has_many :waterings, through: :plants
  has_many :soil_moisture_readings, through: :plants

  has_many :zones, dependent: :destroy
  has_many :locations, dependent: :destroy
  has_many :sensors, dependent: :destroy
  has_many :hygro_sensor_readings, dependent: :destroy
  has_many :sensor_types, dependent: :destroy
  has_many :tanks, dependent: :destroy
  has_many :recipe_sources, dependent: :destroy
  has_many :recipes, dependent: :destroy
  has_many :recipe_batches, dependent: :destroy

  enum :moisture_measurement_type, { numeric: 0, categorical: 1 }

  def users
    [owner] + collaborators
  end

  def add_viewer(user)
    add_user_with_role user, :viewer
  end

  def add_editor(user)
    add_user_with_role user, :editor
  end

  def add_user_with_role(user, role)
    if collaborators.include? user
      return 'User is already a collaborator on this project.'
    end
    c = Collaboration.new user: user, project: self, role: role
    if c.save
      c
    else
      c.errors
    end
  end

  def remove_user(user)
    co = collaborations.find_by user_id: user.id
    co.destroy
  end

  def to_s
    self.name || "##{self.id}"
  end

  def next_uid
    starting_id = 1
    max = self.plants.pluck(:uid).reject(&:nil?).max
    max ? max + 1 : starting_id
  end

  def moisture_categories
    SoilMoistureReading.value_categoricals.keys
  end
end
