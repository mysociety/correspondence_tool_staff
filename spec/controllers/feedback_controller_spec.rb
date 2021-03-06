require 'rails_helper'

RSpec.describe FeedbackController, type: :controller do
  let(:user) { create(:user) }
  let(:params)do
    {
      feedback: {
        comment: "This is my feedback"
      }
    }
  end

  describe '#create' do

    context "as an anonymous user" do

      it "redirect to signin if trying to submit new feedback" do
        post :create, params: params
        expect(response).to redirect_to(new_user_session_path)
      end

      it "return 401 if trying to submit new feedback using AJAX" do
        post :create, params: params, xhr: true
        expect(response.code).to eq "401"
      end
    end


    context "as an authenticated user" do

      before{
        sign_in user
        post :create, params: params, xhr: true
      }

      it "return 200 if using AJAX" do
        expect(response.code).to eq "200"
      end

      it 'makes a DB entry' do
        expect(Feedback.first.comment).to eq "This is my feedback"
        expect(Feedback.first.email).to eq user.email
      end

    end
  end
end

