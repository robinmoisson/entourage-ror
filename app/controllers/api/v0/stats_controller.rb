module Api
  module V0
    class StatsController < Api::V0::BaseController
      skip_before_filter :require_login

      def index
        render json: { tours: Tour.count,
                       encounters: Encounter.count,
                       organizations: Organization.count }.to_json
      end
    end
  end
end
