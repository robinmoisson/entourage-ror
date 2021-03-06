class CreateSnapToRoadTourPoints < ActiveRecord::Migration
  def change
    create_table :snap_to_road_tour_points do |t|
      t.float :latitude, null: false
      t.float :longitude, null: false
      t.integer :tour_id, null: false
    end

    add_index :snap_to_road_tour_points, :tour_id
  end
end
