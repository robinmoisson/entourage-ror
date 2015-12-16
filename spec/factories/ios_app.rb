FactoryGirl.define do
  factory :ios_app, class: Rpush::Apns::App do
    name 'entourage'
    certificate File.read File.join(Rails.root, 'certificates', 'ios_push_sandbox.pem')
    environment "sandbox"
    password ""
    connections 1
  end
end