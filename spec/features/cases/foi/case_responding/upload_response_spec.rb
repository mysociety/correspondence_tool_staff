require 'rails_helper'

feature 'Upload response' do
  given(:responder)      { find_or_create(:foi_responder) }
  given(:kase)           { create(:accepted_case) }
  given(:approved_case ) { create(:approved_case) }
  given(:responder_teammate) do
    create :responder, responding_teams: responder.responding_teams
  end

  context 'as the assigned responder' do
    background do
      login_as responder
    end

    scenario 'clicking link on case detail page goes to upload page' do
      cases_show_page.load(id: kase.id)

      cases_show_page.actions.upload_response.click

      expect(cases_upload_responses_page).to be_displayed
    end

    scenario 'restrict upload more responses to an approved case' do
      cases_show_page.load(id: approved_case.id)

      expect(cases_show_page.actions).to have_upload_response
    end

  end

  context 'as a responder on the same team' do
    background do
      login_as responder_teammate
    end

    scenario 'clicking link on case detail page goes to upload page' do
      cases_show_page.load(id: kase.id)

      cases_show_page.actions.upload_response.click

      expect(cases_upload_responses_page).to be_displayed
    end
  end

  context "as a responder that isn't assigned to the case" do
    given(:unassigned_responder) { create(:responder) }

    background do
      login_as unassigned_responder
    end

    scenario "link to case upload page isn't visible on detail page" do
      cases_show_page.load(id: kase.id)

      expect(cases_show_page).not_to have_link('Upload response')
    end
  end

end
