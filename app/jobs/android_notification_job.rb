class AndroidNotificationJob < ActiveJob::Base
  def perform(sender, object, content, device_ids)
    return if device_ids.blank?

    entourage = Rpush::Gcm::App.where(name: 'entourage').first

    if entourage.nil?
      Rails.logger.warn 'No android notification has been sent. Please save a Rpush::Gcm::App in database'
    else
      notification = Rpush::Gcm::Notification.new
      notification.app = entourage
      notification.registration_ids = device_ids
      notification.data = { sender: sender, object: object, content: content }
      notification.save!

      Rpush.push
    end
  end
end