class AdminMailer < ActionMailer::Base
  default from: "contact@entourage.social"

  def received_message(message)
    @message = message
    mail(to: "contact@entourage.social", subject: "Un nouveau message a été envoyé à l'équipe entourage")
  end

  def registration_request(request_id)
    @request = RegistrationRequest.find(request_id)
    mail to: "associations@entourage.social",
         subject: "Nouvelle demandes d'adhésion : #{@request.organization_field('name')}"
  end
end
