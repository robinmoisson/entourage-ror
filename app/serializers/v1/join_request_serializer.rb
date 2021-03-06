module V1
  class JoinRequestSerializer < ActiveModel::Serializer
    attributes :id,
               :email,
               :display_name,
               :status,
               :message,
               :requested_at,
               :avatar_url,
               :partner

    def id
      object.user.id
    end

    def email
      object.user.email
    end

    def requested_at
      object.created_at
    end

    def display_name
      UserPresenter.new(user: object.user).display_name
    end

    def status
      object.persisted? ? object.status : "not requested"
    end

    def avatar_url
      UserServices::Avatar.new(user: object.user).thumbnail_url
    end

    def partner
      return nil unless object.user.default_partner
      JSON.parse(V1::PartnerSerializer.new(object.user.default_partner, scope: {user: object.user}, root: false).to_json)
    end
  end
end
