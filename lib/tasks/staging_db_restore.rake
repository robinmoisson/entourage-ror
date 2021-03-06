namespace :db do
  task remove_old_points: :environment do
    #Keep the latest 3000 tour points to stay below row limit
    last_id = TourPoint.limit(3000).last.id
    TourPoint.where("id < #{last_id}").delete_all
    Tour.joins("LEFT OUTER JOIN tour_points on tour_points.tour_id = tours.id").where("tour_points.id IS NULL").delete_all

    #delete push token
    User.where("id NOT IN (93, 6, 1, 21, 2)").update_all(device_id: nil)
  end
end