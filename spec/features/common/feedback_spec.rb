require 'rails_helper'

feature "Submitting feedback" do
  let(:user) { create(:user) }

  scenario "Cannot submit feedback from login page" do
    login_page.load
    expect(login_page).to have_no_service_feedback
  end

  scenario "user signed in and wants to submit feedback without comment", js: true do

    login_as user
    cases_page.load
    expect(cases_page).to have_service_feedback
    expect(cases_page.service_feedback).to have_feedback_form
    expect(cases_page.service_feedback).to have_send_button

    cases_page.service_feedback.feedback_textarea.set ""
    cases_page.service_feedback.send_button.click

    cases_page.service_feedback.wait_for_error_notice
    expect(cases_page.service_feedback).to have_error_notice
  end

  scenario "user signed in and wants to submit feedback", js: true do


    login_as user
    cases_page.load

    expect(cases_page).to have_service_feedback
    expect(cases_page.service_feedback).to have_feedback_form
    expect(cases_page.service_feedback).to have_send_button

    cases_page.service_feedback.feedback_textarea.set "Very good service"
    cases_page.service_feedback.send_button.click

    cases_page.service_feedback.wait_for_success_notice
    expect(cases_page.service_feedback).to have_success_notice
    expect(cases_page.service_feedback.feedback_textarea.text).to eq ""
    expect(Feedback.first.comment).to eq "Very good service"
    expect(Feedback.first.email).to eq user.email

  end
end