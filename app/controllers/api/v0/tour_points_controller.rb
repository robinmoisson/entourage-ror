module Api
  module V0
    class TourPointsController < Api::V0::BaseController
      def create
        tour = Tour.find(params[:tour_id])
        tour_points_builder = TourPointsServices::TourPointsBuilder.new(tour, params['tour_points'], :fail_with_log)
        if tour_points_builder.create
          render json: tour, status: 201, serializer: ::V0::TourSerializer
        else
          render json: {message: 'Could not create tour points'}, status: 400
        end
      end
    end
  end
end