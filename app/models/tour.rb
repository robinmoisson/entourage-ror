class Tour < ActiveRecord::Base

  validates :tour_type, inclusion: { in: %w(social food other) }
  has_many :tour_points
  has_many :encounters
  
end