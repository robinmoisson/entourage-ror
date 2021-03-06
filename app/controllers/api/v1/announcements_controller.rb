module Api
  module V1
    class AnnouncementsController < Api::V1::BaseController
      skip_before_filter :authenticate_user!, only: [:icon, :avatar]

      def icon
        icon = {
          2 => :heart,
          3 => :pin,
          4 => :video,
          5 => :megaphone,
          6 => :megaphone,
        }[params[:id].to_i]

        redirect_to view_context.asset_url("assets/announcements/icons/#{icon}.png")
      end

      def avatar
        redirect_to view_context.asset_url("assets/announcements/avatars/1.jpg")
      end

      def redirect
        id = params[:id].to_i

        case id
        when 2
          url = "https://www.entourage.social/don" +
                  "?firstname=#{current_user.first_name}" +
                  "&lastname=#{current_user.last_name}" +
                  "&email=#{current_user.email}" +
                  "&external_id=#{current_user.id}" +
                  "&utm_medium=APP" +
                  "&utm_campaign=DEC2017"

          if current_user.id % 2 == 0
            url += "&utm_source=APP-S1"
          else
            url += "&utm_source=APP-S2"
          end
        when 3
          user_id = UserServices::EncodedId.encode(current_user.id)
          url = "https://entourage-asso.typeform.com/to/WIg5A9?user_id=#{user_id}"
        when 4
          url = "http://www.simplecommebonjour.org/?p=153"
        when 6
          url = "https://blog.entourage.social/2018/01/15/securite-et-moderation/"
        end

        mixpanel.track("Opened Announcement", { "Announcement" => id })

        redirect_to url
      end
    end
  end
end
