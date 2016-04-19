module V1
  class EntourageInvitationSerializer < ActiveModel::Serializer
    attributes :id,
               :inviter_id,
               :invitation_mode,
               :phone_number,
               :entourage_id

    def entourage_id
      object.invitable_id
    end
  end
end