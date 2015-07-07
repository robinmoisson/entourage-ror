class TourPointsController < ApplicationController
  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }

  def create
    if @tour = Tour.find_by(id:params[:tour_id])
      @tour_point = @tour.tour_points.create(tour_point_params)
      if @tour_point.valid?
        render "tours/show", status: 201
      else
        render "400", status: 400
      end
    else
      @id = params[:tour_id]
      render "tours/404", status: 404
    end
  end

  def tour_point_params
    params.require(:tour_point).permit(:latitude, :longitude, :passing_time)
  end

end