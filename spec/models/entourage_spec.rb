require 'rails_helper'

RSpec.describe Entourage, type: :model do
  it { expect(FactoryGirl.build(:entourage).save!).to be true }
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:entourage_type) }
  it { should validate_presence_of(:user_id) }
  it { should validate_presence_of(:latitude) }
  it { should validate_presence_of(:longitude) }
  it { should validate_presence_of(:number_of_people) }
  it { should validate_inclusion_of(:status).in_array(["open", "closed"]) }
  it { should validate_inclusion_of(:entourage_type).in_array(["ask_for_help"]) }
  it { should belong_to(:user) }

  it "has many members" do
    user = FactoryGirl.create(:public_user)
    entourage = FactoryGirl.create(:entourage)
    EntouragesUser.create(user: user, entourage: entourage)
    expect(entourage.members).to eq([user])
  end

  it "has many chat messages" do
    entourage = FactoryGirl.create(:entourage)
    chat_message = FactoryGirl.create(:chat_message, messageable: entourage)
    expect(entourage.chat_messages).to eq([chat_message])
  end
end
