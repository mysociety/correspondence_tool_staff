require 'rails_helper'

describe 'cases/approve_response.html.slim' do
  let(:assigned_trigger_case)   { create :assigned_case, :flagged_accepted}

  it 'displays all the cases' do
    assign(:case, assigned_trigger_case)

    render

    approve_response_page.load(rendered)
    page = approve_response_page

    expect(page.page_heading.heading.text).to eq "Clear response"
    expect(page.page_heading.sub_heading.text)
        .to eq "You are viewing case number #{assigned_trigger_case.number} "

    expect(page).to have_clearance

    expect(page).to have_submit_button
  end
end
