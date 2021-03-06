require 'rails_helper'

RSpec.describe Api::V1::UserApplicationsController, type: :controller do

  describe "PUT #update" do
    context "user not signed in" do
      before { put :update, application: {push_token: "foobar", device_os: "ios", version: "1.1"} }
      it { expect(response.status).to eq 401 }
    end

    context "user signed in" do
      let(:user) { FactoryGirl.create(:pro_user) }

      context "new application" do
        before { put :update, application: {push_token: "foobar", device_os: "ios", version: "1.1"}, token: user.token }
        it { expect(response.status).to eq 204 }
        it { expect(user.user_applications.count).to eq(1) }
        it { expect(user.user_applications.first.push_token).to eq("foobar") }
      end

      context "application already exist with another token" do
        let!(:ios_user_application_old) { FactoryGirl.create(:user_application, user: user, push_token: "old_token2", device_os: "ios", version: "1.0") }
        let!(:ios_user_application) { FactoryGirl.create(:user_application, user: user, push_token: "old_token", device_os: "ios", version: "1.1") }
        before { put :update, application: {push_token: "foobar", device_os: "ios", version: "1.1"}, token: user.token }
        it { expect(user.user_applications.count).to eq(2) }
        it { expect(user.user_applications.last.push_token).to eq("foobar") }
      end

      context "application already exist with same token" do
        let!(:ios_user_application_old) { FactoryGirl.create(:user_application, user: user, push_token: "old_token2", device_os: "ios", version: "1.0") }
        let!(:ios_user_application) { FactoryGirl.create(:user_application, user: user, push_token: "foobar", device_os: "ios", version: "1.1") }
        before { put :update, application: {push_token: "foobar", device_os: "ios", version: "1.1"}, token: user.token }
        it { expect(user.user_applications.count).to eq(2) }
        it { expect(user.user_applications.last.push_token).to eq("foobar") }
      end

      context "another device family application exists" do
        let!(:android_user_application) { FactoryGirl.create(:user_application, user: user, push_token: "old_token", device_os: "android", version: "1.1") }
        before { put :update, application: {push_token: "foobar", device_os: "ios", version: "1.1"}, token: user.token }
        it { expect(user.user_applications.count).to eq(2) }
        it { expect(user.user_applications.where(device_os: "ios").first.push_token).to eq("foobar") }
      end

      context "another user exists with same token" do
        let!(:android_user_application) { FactoryGirl.create(:user_application, push_token: "foobar", device_os: "android", version: "1.1") }
        before { put :update, application: {push_token: "foobar", device_os: "ios", version: "1.1"}, token: user.token }
        it { expect(UserApplication.count).to eq(1) }
      end

      context "remove ios application token" do
        let!(:ios_user_application_old) { FactoryGirl.create(:user_application, user: user, push_token: "old_token2", device_os: "ios", version: "1.0") }
        let!(:ios_user_application) { FactoryGirl.create(:user_application, user: user, push_token: "old_token", device_os: "ios", version: "1.1") }
        before { put :update, application: {push_token: "0", device_os: "ios", version: "1.1"}, token: user.token }
        it { expect(user.user_applications.count).to eq(1) }
        it { expect(user.user_applications.last.push_token).to eq("old_token2") }
      end

      context "remove android application token" do
        let!(:ios_user_application_old) { FactoryGirl.create(:user_application, user: user, push_token: "old_token2", device_os: "android", version: "1.0") }
        let!(:ios_user_application) { FactoryGirl.create(:user_application, user: user, push_token: "old_token", device_os: "android", version: "1.1") }
        before { put :update, application: {push_token: "", device_os: "android", version: "1.1"}, token: user.token }
        it { expect(user.user_applications.count).to eq(1) }
        it { expect(user.user_applications.last.push_token).to eq("old_token2") }
      end

    end
  end
end
